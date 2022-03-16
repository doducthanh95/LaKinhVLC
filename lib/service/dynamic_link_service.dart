import 'package:LaKinhVLC/bloc/map_bloc.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DynamicLinkService {
  MapBloc mapBloc;

  DynamicLinkService(this.mapBloc);

  Future<Uri> handleDynamicLinks() async {
    await Future.delayed(Duration(seconds: 3));

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      if (deepLink != null) {
        return _handleDeepLink(dynamicLink);
      }
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
      return null;
    });

    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      return deepLink;
    }
    return null;
  }

  Uri _handleDeepLink(PendingDynamicLinkData data) {
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      print('_handleDeepLink: ${data.link}');
      final array = deepLink.toString().split('&');
      if (array.length < 1) return null;
      double lat = double.tryParse(array[1]) ?? 0;
      double long = double.tryParse(array[2]) ?? 0;
      mapBloc.zoom = double.tryParse(array[3]) ?? 20;
      mapBloc.isShowCurrentPositon = false;
      mapBloc.positionDeepLink = Position(latitude: lat, longitude: long);
      mapBloc.setPositionFromDeepLink(LatLng(lat, long));
    }
    return deepLink;
  }

  Future<String> createDynamicLink(LatLng lat, double zoom) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
        uriPrefix: 'https://flutterapplaban.page.link',
        link: Uri.parse(
          'https://flutterapplaban.page.link/post&${lat.latitude}&${lat.longitude}&${mapBloc.zoom}',
        ),
        androidParameters: AndroidParameters(
          packageName: 'com.example.flutter_app_la_ban',
        ),
        iosParameters: IosParameters(
            bundleId: 'com.example.flutterAppLaBan',
            minimumVersion: '1.0',
            //appStoreId: "1481524675"));
            appStoreId: '1534484049'));
    ShortDynamicLink dynamicUrl = await parameters.buildShortLink();
    return dynamicUrl.shortUrl.toString();
  }
}
