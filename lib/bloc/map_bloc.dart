import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:LaKinhVLC/position.dart';

class MapBloc {
  BehaviorSubject<double> _object = BehaviorSubject<double>();
  BehaviorSubject<double> _objectMap = BehaviorSubject<double>();
  BehaviorSubject<LatLng> _objectDeepLink = BehaviorSubject<LatLng>();
  BehaviorSubject<Uint8List> _objectMapSnapshoot = BehaviorSubject<Uint8List>();
  BehaviorSubject<bool> _objectTakeImage = BehaviorSubject<bool>();
  Stream<double> get stream => _object.stream;
  Stream<double> get streamMap => _objectMap.stream;
  Stream<LatLng> get streamDeepLink => _objectDeepLink.stream;
  Stream<Uint8List> get streamMapSnapshoot => _objectMapSnapshoot.stream;
  Stream<bool> get streamTakeImage => _objectTakeImage.stream;

  var _currentPosition = MyPosition(longitude: 0, latitude: 0);
  double zoom = 20;

  bool isShowCurrentPositon = true;
  MyPosition? positionDeepLink;

  updateCurrentPosition(MyPosition newPosition) {
    _currentPosition = newPosition;
  }

  void setPositionFromDeepLink(LatLng lat) {
    _objectDeepLink.add(lat);
  }

  LatLng getPosition() {
    return LatLng(_currentPosition.latitude, _currentPosition.longitude);
  }

  setAngle(double value) {
    _object.add(value);
  }

  setAngleForCompass(double value) {
    _objectMap.add(value);
  }

  Future<MyPosition?> getLocation() async {
    Position currentLocation;
    try {
      currentLocation = await Geolocator.getCurrentPosition();
      if (!isShowCurrentPositon && positionDeepLink != null) {
        return MyPosition(
            latitude: positionDeepLink?.latitude ?? 0,
            longitude: positionDeepLink?.longitude ?? 0);
      } else {
        return MyPosition(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude);
      }
    } on Exception {
      return null;
    }
  }

  takeMapSnapshot() {
    _objectTakeImage.add(true);
  }

  createGoogleMapImage(Uint8List data) {
    _objectMapSnapshoot.add(data);
  }

  dispose() {
    _object.close();
    _objectMap.close();
    _objectDeepLink.close();
    _objectMapSnapshoot.close();
  }
}
