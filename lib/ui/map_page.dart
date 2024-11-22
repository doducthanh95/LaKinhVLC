import 'dart:async';
import 'dart:typed_data';

import 'package:LaKinhVLC/bloc/map_bloc.dart';
import 'package:LaKinhVLC/const/const_value.dart';
import 'package:LaKinhVLC/position.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_api_headers/google_api_headers.dart';

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiAndroidKey);

class MapPage extends StatefulWidget {
  final MapBloc bloc;
  final BuildContext parentContext;

  const MapPage({required this.bloc, required this.parentContext});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  final Completer<GoogleMapController> _controller = Completer();

  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  MyPosition _position =
      MyPosition(latitude: 37.42796133580664, longitude: -122.085749655962);
  double angle = 0;

  CameraPosition? _kGooglePlex;

  StreamSubscription? subscription;
  StreamSubscription? subscriptionCompass;

  var markers = Set<Marker>();
  MarkerId? selectedMarker;
  int _markerIdCounter = 1;

  late GoogleMapController _googleMapController;

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

    widget.bloc.streamTakeImage.listen((event) async {
      final data = await _googleMapController.takeSnapshot();

      if (data == null) {
        return;
      }
      widget.bloc.createGoogleMapImage(data);
    });

    super.initState();

    subscriptionCompass = widget.bloc.streamDeepLink.listen((event) {
      _updatePosition(
          MyPosition(latitude: event.latitude, longitude: event.longitude), 20);
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscriptionCompass?.cancel();
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
          initialCameraPosition: _kGooglePlex ??
              CameraPosition(
                target: LatLng(_position.latitude, _position.longitude),
                tilt: 10,
                bearing: angle,
                zoom: widget.bloc.zoom,
              ),
          onMapCreated: (GoogleMapController controller) {
            _googleMapController = controller;
            _controller.complete(controller);
          },
          onCameraMove: (p) {
            if (isUseCompass) {
              return;
            }
            widget.bloc.setAngleForCompass(p.bearing);
            widget.bloc.updateCurrentPosition(MyPosition(
                latitude: p.target.latitude, longitude: p.target.longitude));
            widget.bloc.zoom = p.zoom;
            _position = MyPosition(
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

  _updatePosition(MyPosition? data, double agle) {
    _controller.future.then((value) {
      var _ = CameraPosition(
          target: LatLng(data?.latitude ?? 0.0, data?.longitude ?? 0.0),
          bearing: agle,
          tilt: 10,
          zoom: widget.bloc.zoom);
      value.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(data?.latitude ?? 0.0, data?.longitude ?? 0.0),
          widget.bloc.zoom));
    });
  }

  void _fetchPermissionStatus() async {
    var permissionLocation = await Permission.location.isGranted;
    if (!permissionLocation) {
      //AppSettings.openLocationSettings();
      final result = await Permission.location.request();
      if (result == PermissionStatus.granted) {
        setState(() {});
        return;
      }
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
                      AppSettings.openAppSettings().then((value) {
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
        _position = MyPosition(
            latitude: position?.latitude ?? 0.0,
            longitude: position?.longitude ?? 0.0);
        _updatePosition(position, 0);
      } else {
        _updatePosition(
            MyPosition(
                latitude: widget.bloc.positionDeepLink?.latitude ?? 0.0,
                longitude: widget.bloc.positionDeepLink?.longitude ?? 0.0),
            0);
      }
    });
  }

  Future<Null> displayPrediction(
      Prediction prediction, ScaffoldState scaffold) async {
    if (prediction != null) {
      // get detail (lat/lng)
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(prediction.placeId ?? '');
      final lat = detail.result.geometry?.location.lat ?? 0.0;
      final lng = detail.result.geometry?.location.lng ?? 0.0;

      _position = MyPosition(longitude: lng, latitude: lat);

      _updatePosition(MyPosition(longitude: lng, latitude: lat), 0);
    }
  }

  Future<Null> displayPredictionV2(Prediction? prediction) async {
    if (prediction != null) {
      // get detail (lat/lng)
      GoogleMapsPlaces _places = GoogleMapsPlaces(
        apiKey: kGoogleApiAndroidKey,
        apiHeaders: await GoogleApiHeaders().getHeaders(),
      );
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(prediction.placeId ?? '');
      final lat = detail.result.geometry?.location.lat ?? 0.0;
      final lng = detail.result.geometry?.location.lng ?? 0.0;
      _position = MyPosition(longitude: lng, latitude: lat);

      _updatePosition(MyPosition(longitude: lng, latitude: lat), 0);

      _add(_position);
    }
  }

  _searchLocation() async {
    Prediction? p = await PlacesAutocomplete.show(
        context: context,
        apiKey: kGoogleApiAndroidKey,
        mode: Mode.overlay, // Mode.fullscreen
        language: "vi",
        components: [new Component(Component.country, "vn")]);
    displayPredictionV2(
      p,
    );
  }

  void _add(MyPosition position) async {
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
