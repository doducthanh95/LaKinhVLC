// import 'dart:ffi';
// import 'dart:math';
// import 'package:rxdart/rxdart.dart';
// import 'package:sensors/sensors.dart';
//
// class CompassBloc {
//   final _bloc = BehaviorSubject<double>();
//   Stream<double> get compassStream => _bloc.stream;
//
//   final _blocChangeMapView = BehaviorSubject<double>();
//   Stream<double> get changeMapViewStream => _blocChangeMapView.stream;
//
//   List<double> mGravity = [0, 0, 0];
//   List<double> mGeomagnetic = [0, 0, 0];
//   List<double> R = [0, 0, 0, 0, 0, 0, 0, 0, 0];
//   List<double> I = [0, 0, 0, 0, 0, 0, 0, 0, 0];
//
//   double azimuth;
//   double azimuthFix = -25;
//
//   setValueDirection(double value) {
//     _bloc.add(value);
//   }
//
//   setChangeMapView(double value) {
//     _blocChangeMapView.add(value);
//   }
//
//   setCurrentDirection() {}
//
//   bool getRorarionMatrix(List<double> R, List<double> I, List<double> gravity,
//       List<double> geomagnetic) {
//     double Ax = gravity[0];
//     double Ay = gravity[1];
//     double Az = gravity[2];
//
//     final double normsqA = (Ax * Ax + Ay * Ay + Az * Az);
//     final double g = 9.81;
//     final double freeFallGravitySquared = 0.01 * g * g;
//     if (normsqA < freeFallGravitySquared) {
//       return false;
//     }
//     final double Ex = geomagnetic[0];
//     final double Ey = geomagnetic[1];
//     final double Ez = geomagnetic[2];
//
//     double Hx = Ey * Az - Ez * Ay;
//     double Hy = Ez * Ax - Ex * Az;
//     double Hz = Ex * Ay - Ey * Ax;
//
//     final double normH = sqrt(Hx * Hx + Hy * Hy + Hz * Hz);
//
//     if (normH < 0.1) {
//       return false;
//     }
//
//     final double invH = 0.1 / normH;
//     Hx *= invH;
//     Hy *= invH;
//     Hz *= invH;
//
//     final double invA = 1.0 / sqrt(Ax * Ax + Ay * Ay + Az * Az);
//     Ax *= invA;
//     Ay *= invA;
//     Az *= invA;
//
//     final double Mx = Ay * Hz - Az * Hy;
//     final double My = Az * Hx - Ax * Hz;
//     final double Mz = Ax * Hy - Ay * Hx;
//     if (R != null) {
//       R[0] = Hx;
//       R[1] = Hy;
//       R[2] = Hz;
//       R[3] = Mx;
//       R[4] = My;
//       R[5] = Mz;
//       R[6] = Ax;
//       R[7] = Ay;
//       R[8] = Az;
//     }
//     if (I != null) {
//       final double invE = 1.0 / sqrt(Ex * Ex + Ey * Ey + Ez * Ez);
//       final double c = (Ex * Mx + Ey * My + Ez * Mz) * invE;
//       final double s = (Ex * Ax + Ey * Ay + Ez * Az);
//
//       I[0] = 1;
//       I[1] = 0;
//       I[2] = 0;
//       I[3] = 0;
//       I[4] = c;
//       I[5] = s;
//       I[6] = 0;
//       I[7] = -s;
//       I[8] = c;
//     }
//     return true;
//   }
//
//   List<double> getOrientation(List<double> R, List<double> values) {
//     values[0] = atan2(R[1], R[4]);
//     values[1] = asin(-R[7]);
//     values[2] = atan2(-R[6], R[8]);
//     return values;
//   }
//
//   onSensorAcceleChanged(AccelerometerEvent event) {
//     final double alpha = 0.9;
//
//     mGravity[0] = 0.9 * mGravity[0] + (1 - alpha) * event.x;
//     mGravity[1] = 0.9 * mGravity[1] + (1 - alpha) * event.y;
//     mGravity[2] = 0.9 * mGravity[2] + (1 - alpha) * event.z;
//
//     bool success = getRorarionMatrix(R, I, mGravity, mGeomagnetic);
//     List<double> orientation = [];
//     getOrientation(R, orientation);
//     azimuth = orientation[0] * 180 / pi;
//     azimuth = (azimuth + azimuthFix + 360) % 360;
//
//     print("ddthanh $azimuth");
//   }
//
//   double onSensorMagneChanged(GyroscopeEvent event) {
//     final double alpha = 0.95;
//
//     mGravity[0] = 0.9 * mGeomagnetic[0] + (1 - alpha) * event.x;
//     mGravity[1] = 0.9 * mGeomagnetic[1] + (1 - alpha) * event.y;
//     mGravity[2] = 0.9 * mGeomagnetic[2] + (1 - alpha) * event.z;
//
//     bool success = getRorarionMatrix(R, I, mGravity, mGeomagnetic);
//     List<double> orientation = [];
//     getOrientation(R, orientation);
//     azimuth = orientation[0] * 180 / pi;
//     azimuth = (azimuth + azimuthFix + 360) % 360;
//     print("ddthanh $azimuth");
//   }
//
//   dispose() {
//     _bloc.close();
//     _blocChangeMapView.close();
//   }
// }
