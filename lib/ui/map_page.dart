import 'dart:async';

import 'package:LaKinhVLC/bloc/map_bloc.dart';
import 'package:LaKinhVLC/const/const_value.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_api_headers/google_api_headers.dart';

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiAndroidKey);

class MapPage extends StatefulWidget {
  MapBloc bloc;
  BuildContext parentContext;

  MapPage({this.bloc, this.parentContext});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  final Completer<GoogleMapController> _controller = Completer();

  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  Position _position =
      Position(latitude: 37.42796133580664, longitude: -122.085749655962);
  double angle = 0;

  CameraPosition _kGooglePlex;

  StreamSubscription subscription;
  StreamSubscription subscriptionCompass;

  var markers = Set<Marker>();
  MarkerId selectedMarker;
  int _markerIdCounter = 1;

  @override
  void initState() {
    _kGooglePlex = CameraPosition(
      target: LatLng(_position.latitude, _position.longitude),
      tilt: 10,
      bearing: angle,
      zoom: widget.bloc.zoom,
    );

    WidgetsBinding.instance.addObserver(this);
    _getCurrentPosition();
    _fetchPermissionStatus();

    widget.bloc.streamTakeImage.listen((event) {
      return _controller.future.then((value) {
        value
            .takeSnapshot()
            .then((value) => widget.bloc.createGoogleMapImage(value));
      });
    });

    super.initState();

    subscriptionCompass = widget.bloc.streamDeepLink.listen((event) {
      _updatePosition(
          Position(latitude: event.latitude, longitude: event.longitude), 20);
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscriptionCompass.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          buildingsEnabled: true,
          myLocationEnabled: true,
          mapToolbarEnabled: true,
          rotateGesturesEnabled: true,
          compassEnabled: true,
          mapType: MapType.hybrid,
          indoorViewEnabled: true,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          onCameraMove: (p) {
            if (isUseCompass) {
              return;
            }
            widget.bloc.setAngleForCompass(p.bearing);
            widget.bloc.updateCurrentPosition(Position(
                latitude: p.target.latitude, longitude: p.target.longitude));
            widget.bloc.zoom = p.zoom;
            _position = Position(
                latitude: p.target.latitude, longitude: p.target.longitude);
          },
          markers: markers,
        ),
        Positioned(
          left: 20,
          bottom: 10,
          child: FloatingActionButton(
              child: Icon(Icons.search),
              onPressed: () {
                _searchLocation();
              }),
        ),
      ],
    );
  }

  _updatePosition(Position data, double agle) {
    _controller.future.then((value) {
      var position = CameraPosition(
          target: LatLng(data.latitude, data.longitude),
          bearing: agle ?? 0,
          tilt: 10,
          zoom: widget.bloc.zoom);
      value.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(data.latitude, data.longitude), widget.bloc.zoom));
    });
  }

  void _fetchPermissionStatus() async {
    if (await _checkIsFirstRunApp()) {
      return;
    }
    var permissionLocation = await Permission.locationWhenInUse.status;
    if (permissionLocation != PermissionStatus.granted) {
      //AppSettings.openLocationSettings();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                content: Text(
                    "Bạn cần cấp quyền vị trí cho ứng dụng để hiển thị chính xác bản đồ"),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Huỷ"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      AppSettings.openLocationSettings().then((value) {
                        _getCurrentPosition();
                      });
                    },
                    child: Text("Đồng ý"),
                  )
                ],
              ));
    }
  }

  Future<bool> _checkIsFirstRunApp() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    if (_preference.getBool("IsFirstRun") ?? true) {
      _preference.setBool("IsFirstRun", false);
      return true;
    }
    return false;
  }

  _getCurrentPosition() async {
    widget.bloc.getLocation().then((position) {
      if (widget.bloc.isShowCurrentPositon) {
        _position = position;
        _updatePosition(position, 0);
      } else {
        _updatePosition(widget.bloc.positionDeepLink, 0);
      }
    });
  }

  Future<Null> displayPrediction(Prediction p, ScaffoldState scaffold) async {
    if (p != null) {
      // get detail (lat/lng)
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;

      _position = Position(longitude: lng, latitude: lat);

      _updatePosition(Position(longitude: lng, latitude: lat), 0);
    }
  }

  Future<Null> displayPredictionV2(Prediction p, ScaffoldState scaffold) async {
    if (p != null) {
      // get detail (lat/lng)
      GoogleMapsPlaces _places = GoogleMapsPlaces(
        apiKey: kGoogleApiAndroidKey,
        apiHeaders: await GoogleApiHeaders().getHeaders(),
      );
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;
      _position = Position(longitude: lng, latitude: lat);

      _updatePosition(Position(longitude: lng, latitude: lat), 0);

      _add(_position);
    }
  }

  _searchLocation() async {
    Prediction p = await PlacesAutocomplete.show(
        context: context,
        apiKey: kGoogleApiAndroidKey,
        mode: Mode.overlay, // Mode.fullscreen
        language: "vi",
        components: [new Component(Component.country, "vn")]);
    displayPredictionV2(p, homeScaffoldKey.currentState);
  }

  void _add(Position position) async {
    markers.clear();
    final center = _position;
    final int markerCount = markers.length;

    if (markerCount == 12) {
      return;
    }

    final String markerIdVal = 'marker_id_$_markerIdCounter';
    _markerIdCounter++;
    final MarkerId markerId = MarkerId(markerIdVal);

    BitmapDescriptor markerbitmap = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(),
      "assets/images/icMarker.png",
    );

    final Marker marker = Marker(
        // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        markerId: markerId,
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(title: '', snippet: ''),
        icon: markerbitmap);

    setState(() {
      markers.add(marker);
    });
  }
}
