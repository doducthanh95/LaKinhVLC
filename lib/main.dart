import 'package:LaKinhVLC/const/const_value.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:LaKinhVLC/ui/home_page.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'ui/home_page.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StyledToast(
      locale: Locale("vi", "VN"),
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // This is the theme of your application.
            primarySwatch: Colors.blue,
            //visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: HomePage()
          //home: HomePage(),
          ),
    );
  }
}

Future<RemoteConfig> setupRemoteConfig() async {
  final RemoteConfig remoteConfig = await RemoteConfig.instance;

  await remoteConfig.fetch();
  await remoteConfig.activateFetched();

//testing
  kGoogleApiAndroidKey = remoteConfig.getString("google_map_api");

  return remoteConfig;
}
