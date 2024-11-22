import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:LaKinhVLC/bloc/map_bloc.dart';
import 'package:LaKinhVLC/const/const_value.dart';
import 'package:LaKinhVLC/main.dart';
import 'package:LaKinhVLC/service/dynamic_link_service.dart';
import 'package:LaKinhVLC/ui/compass_page.dart';
import 'package:LaKinhVLC/ui/map_page.dart';
import 'package:LaKinhVLC/ui/one_event.dart';
import 'package:LaKinhVLC/utitlities/utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:ui' as ui;

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  double agle = 0;
  ScreenshotController _screenshotController = ScreenshotController();
  final _bloc = MapBloc();
  DynamicLinkService? _dynamicLink;

  GlobalKey _containerKey = GlobalKey();

  Uint8List? _image;
  Uint8List? _image2;
  bool _isShowChildScreen = false;
  StreamController<OneEvent> _streamController = StreamController<OneEvent>();

  @override
  void initState() {
    // _getRemoteConfig();
    _initData();

    _bloc.streamMapSnapshoot.listen((event) async {
      _image = event;
      await ImageGallerySaver.saveImage(event);
      // setState(() {});
      // _capturePng();
    });
    super.initState();
  }

  _initData() async {
    Future.wait([setupRemoteConfig()]);
    _dynamicLink = DynamicLinkService(_bloc);
    _handleDeepLink();

    setState(() {});
  }

  void _capturePng() async {
    RenderRepaintBoundary? renderRepaintBoundary = _containerKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    ui.Image? boxImage = await renderRepaintBoundary?.toImage(pixelRatio: 1);
    ByteData? byteData =
        await boxImage?.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? uInt8List = byteData?.buffer.asUint8List();
    _image2 = uInt8List;
    _isShowChildScreen = true;
    setState(() {
      Future.delayed(Duration(seconds: 1)).then((value) async {
        await _screenshotController
            .capture(delay: const Duration(milliseconds: 10))
            .then((Uint8List? image) async {
          try {
            if (byteData != null) {
              final result = await ImageGallerySaver.saveImage(
                  byteData.buffer.asUint8List());
              print(result);
            }

            if (image != null) {
              final directory = await getApplicationDocumentsDirectory();
              final _ = await File('${directory.path}/image.png').create();

              File('$directory/file_name${DateTime.now()}.png')
                  .writeAsBytes(image);
              await ImageGallerySaver.saveImage(image);
            }
          } catch (e) {
            print(e);
          } finally {
            setState(() {
              _isShowChildScreen = false;
            });
          }
        });
      });
    });
  }

  void _handleDeepLink() async {
    _dynamicLink?.handleDynamicLinks();
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
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OneEvent>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blueAccent,
              surfaceTintColor: Colors.blueAccent,
              centerTitle: true,
              title: GestureDetector(
                onTap: _openWeb,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'appTitle'.tr(),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Icon(
                      Icons.info,
                      color: Colors.white,
                    )
                  ],
                ),
              ),
              leading: Switch(
                value: isUseCompass,
                activeColor: Colors.white,
                onChanged: (isOn) {
                  setState(() {
                    isUseCompass = isOn;
                  });
                },
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      if (language == 'vi') {
                        _streamController.sink.add(OneEvent(isVi: false));
                        language = 'ch';
                        return;
                      }
                      _streamController.sink.add(OneEvent(isVi: true));
                      language = 'vi';
                    },
                    icon: Icon(
                      Icons.translate,
                      color: Colors.white,
                    )),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
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
                      direction: 0.0,
                      callBack: (v) {},
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
        });
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
                      image: MemoryImage(_image!),
                    ),
                    Image(image: MemoryImage(_image2 ?? Uint8List(128)))
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
    String? url =
        await _dynamicLink?.createDynamicLink(_bloc.getPosition(), 20);
    await Share.share(url ?? '', subject: 'Chia sẻ vị trí');
  }

  _captureScreen() async {
    Navigator.pop(context);
    print("File Saved to Gallery");
    _bloc.takeMapSnapshot();
  }

  // Future<void> _requestPermission() async {
  //   await [Permission.storage, Permission.location].request();
  // }

  _openWeb() async {
    final url = Uri.parse('https://www.thayhuyenphongthuy.com');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
