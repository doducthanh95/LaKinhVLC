import 'dart:async';
import 'dart:math';
import 'package:LaKinhVLC/bloc/map_bloc.dart';
import 'package:LaKinhVLC/const/const_value.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/material.dart';

class CompassPage extends StatefulWidget {
  double direction;
  Function(double) callBack;
  MapBloc bloc;
  CompassPage({this.direction, this.callBack, this.bloc});

  @override
  _CompassPageState createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> with WidgetsBindingObserver {
  //final bloc = CompassBloc();

  StreamSubscription _compassSub;
  StreamSubscription _compassSubMap;

  String alpha = "0";
  double alphaRotate = 0;

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addObserver(this);

    super.initState();

    _compassSub = FlutterCompass.events.listen((value) {
      if (isUseCompass) {
        double coordinate = value.heading;
        alphaRotate = coordinate;
        setState(() {
          alpha = double.parse((coordinate).toStringAsFixed(2)).toString();
        });
        widget.bloc.setAngle(coordinate);
      }
    });

    _compassSubMap = widget.bloc.streamMap.listen((event) {
      alphaRotate = event;
      setState(() {
        alpha = double.parse((event).toStringAsFixed(2)).toString();
      });
      widget.bloc.setAngle(alphaRotate);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _compassSub.cancel();
    _compassSubMap.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.black.withOpacity(0.1),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                child: StreamBuilder<double>(
                    stream: widget.bloc.stream,
                    builder: (context, snapshot) {
                      double value = widget.direction ?? 0;
                      if (snapshot.hasData) {
                        value = snapshot.data;
                        return Transform.rotate(
                          angle: value * (pi / 180) * -1,
                          child: Opacity(
                              opacity: 0.5,
                              child: Image.asset(
                                "assets/images/compass.png",
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.width * 0.9,
                              )),
                        );
                      } else {
                        return Container();
                      }
                    }),
              ),
              Container(
                child: Image.asset(
                  "assets/images/coordinate.png",
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
          Positioned(
            top: 80,
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  color: Colors.black.withOpacity(0.2),
                ),
                padding: EdgeInsets.all(12),
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: alpha + "\u00B0",
                        style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 26)),
                    TextSpan(
                        text: " " + _getDirectionString(alphaRotate),
                        style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.normal,
                            fontSize: 18))
                  ]),
                )),
          )
        ],
      ),
    ));
  }

  String _getDirectionString(double alpha) {
    if (alpha <= 22.5) {
      return 'Bắc';
    } else if (alpha > 22.5 && alpha <= 67.5) {
      return 'Đông Bắc';
    } else if (alpha > 67.5 && alpha <= 112.5) {
      return 'Đông';
    } else if (alpha > 112.5 && alpha <= 157.5) {
      return 'Đông Nam';
    } else if (alpha > 157.5 && alpha <= 202.5) {
      return 'Nam';
    } else if (alpha > 202.5 && alpha <= 247.5) {
      return 'Tây Nam';
    } else if (alpha > 247.5 && alpha <= 292.5) {
      return 'Tây';
    } else if (alpha > 292.5 && alpha <= 337.5) {
      return 'Tây Bắc';
    } else {
      return 'Bắc';
    }
  }
}
