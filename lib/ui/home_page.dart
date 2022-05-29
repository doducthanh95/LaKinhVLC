import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:LaKinhVLC/bloc/map_bloc.dart';
import 'package:LaKinhVLC/const/const_value.dart';
import 'package:LaKinhVLC/main.dart';
import 'package:LaKinhVLC/service/dynamic_link_service.dart';
import 'package:LaKinhVLC/ui/compass_page.dart';
import 'package:LaKinhVLC/ui/map_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:ui' as ui;

import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  double agle = 0;
  ScreenshotController _screenshotController = ScreenshotController();
  final _bloc = MapBloc();
  DynamicLinkService _dynamicLink;

  GlobalKey _containerKey = GlobalKey();
  GlobalKey _containerKey2 = GlobalKey();

  Uint8List _image;
  Uint8List _image2;
  bool _isShowChildScreen = false;

  var _remoteConfig;

  @override
  void initState() {
    // _getRemoteConfig();
    setupRemoteConfig();
    _dynamicLink = DynamicLinkService(_bloc);
    _handleDeepLink();
    _requestPermission();

    _bloc.streamMapSnapshoot.listen((event) async {
      if (event != null) {
        _image = event;
        _capturePng();
      }
    });
    super.initState();
  }

  void _capturePng() async {
    RenderRepaintBoundary renderRepaintBoundary =
        _containerKey.currentContext.findRenderObject();
    ui.Image boxImage = await renderRepaintBoundary.toImage(pixelRatio: 1);
    ByteData byteData =
        await boxImage.toByteData(format: ui.ImageByteFormat.png);
    Uint8List uInt8List = byteData.buffer.asUint8List();
    _image2 = uInt8List;
    _isShowChildScreen = true;
    setState(() {
      Future.delayed(Duration(seconds: 1)).then((value) async {
        await _screenshotController
            .capture(delay: const Duration(milliseconds: 10))
            .then((Uint8List image) async {
          if (image != null) {
            final directory = await getApplicationDocumentsDirectory();
            final imagePath =
                await File('${directory.path}/image.png').create();

            File('$directory/file_name${DateTime.now()}.png')
                .writeAsBytes(image);
            await ImageGallerySaver.saveFile('${directory.path}/image.png');
            setState(() {
              _isShowChildScreen = false;
            });
          }
        });
      });
    });
  }

  void _handleDeepLink() async {
    _dynamicLink.handleDynamicLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleDeepLink();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("La bàn số"),
        leading: Switch(
          value: isUseCompass,
          activeColor: Colors.greenAccent,
          onChanged: (isOn) {
            setState(() {
              isUseCompass = isOn;
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showMore,
          )
        ],
      ),
      body: Container(
        child: Stack(
          alignment: Alignment.center,
          children: [
            MapPage(
              bloc: _bloc,
              parentContext: context,
            ),
            RepaintBoundary(
              key: _containerKey,
              child: IgnorePointer(
                  child: CompassPage(
                bloc: _bloc,
              )),
            ),
            Visibility(
              visible: _isShowChildScreen,
              child: _captureScreenWidget(),
            )
          ],
        ),
      ),
    );
  }

  Widget _captureScreenWidget() {
    return _image == null
        ? Container()
        : Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              width: MediaQuery.of(context).size.width / 4,
              height: MediaQuery.of(context).size.height / 4 - 20,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue)),
              child: Screenshot(
                controller: _screenshotController,
                child: Stack(
                  children: [
                    Image(
                      image: MemoryImage(_image),
                    ),
                    Image(image: MemoryImage(_image2))
                  ],
                ),
              ),
            ),
          );
  }

  _showMore() {
    showCupertinoModalPopup(
        context: context,
        builder: (builder) {
          return CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                  child: Text("Chia sẻ vị trí"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _shareLocation();
                  }),
              CupertinoActionSheetAction(
                child: Text("Chụp màn hình"),
                onPressed: _captureScreen,
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: Text("Hủy"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          );
        });
  }

  Future<void> _shareLocation() async {
    String url = await _dynamicLink.createDynamicLink(_bloc.getPosition(), 20);
    await Share.share(url, subject: 'Chia sẻ vị trí');
  }

  _captureScreen() async {
    Navigator.pop(context);
    print("File Saved to Gallery");
    _bloc.takeMapSnapshot();
  }

  _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();

    final info = statuses[Permission.storage].toString();
  }
}
