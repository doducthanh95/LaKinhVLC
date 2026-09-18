import 'dart:async';

import 'package:LaKinhVLC/bloc/map_bloc.dart';
import 'package:LaKinhVLC/const/const_value.dart';
import 'package:LaKinhVLC/position.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
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
  MapType _currentMapType = MapType.terrain;

  @override
  void initState() {
    super.initState();
    _loadSavedMapType();

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

    subscriptionCompass = widget.bloc.streamDeepLink.listen((event) {
      _updatePosition(
          MyPosition(latitude: event.latitude, longitude: event.longitude), 20);
    });
  }

  void _loadSavedMapType() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString("selected_map_type");
    if (savedType != null && mounted) {
      setState(() {
        switch (savedType) {
          case 'normal':
            _currentMapType = MapType.normal;
            break;
          case 'terrain':
            _currentMapType = MapType.terrain;
            break;
          case 'satellite':
            _currentMapType = MapType.satellite;
            break;
          case 'hybrid':
          default:
            _currentMapType = MapType.hybrid;
            break;
        }
      });
    }
  }

  void _setMapType(MapType type) async {
    setState(() {
      _currentMapType = type;
    });
    final prefs = await SharedPreferences.getInstance();
    String typeStr = 'terrain';
    if (type == MapType.normal) typeStr = 'normal';
    if (type == MapType.terrain) typeStr = 'terrain';
    if (type == MapType.satellite) typeStr = 'satellite';
    if (type == MapType.hybrid) typeStr = 'hybrid';
    await prefs.setString("selected_map_type", typeStr);
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
          mapType: _currentMapType,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'btnSearch',
                child: const Icon(Icons.search),
                onPressed: () {
                  _searchLocation();
                },
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                heroTag: 'btnMapType',
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                child: const Icon(Icons.layers),
                onPressed: _showMapTypeSelector,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Chọn loại bản đồ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMapTypeOption(
                      icon: Icons.map_outlined,
                      label: "Mặc định",
                      type: MapType.normal,
                    ),
                    _buildMapTypeOption(
                      icon: Icons.terrain,
                      label: "Địa hình",
                      type: MapType.terrain,
                    ),
                    _buildMapTypeOption(
                      icon: Icons.satellite_alt,
                      label: "Vệ tinh",
                      type: MapType.satellite,
                    ),
                    _buildMapTypeOption(
                      icon: Icons.layers,
                      label: "Hỗn hợp",
                      type: MapType.hybrid,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapTypeOption({
    required IconData icon,
    required String label,
    required MapType type,
  }) {
    final isSelected = _currentMapType == type;
    return InkWell(
      onTap: () {
        _setMapType(type);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blue : Colors.grey.shade700,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black87,
              ),
            ),
          ],
        ),
      ),
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
