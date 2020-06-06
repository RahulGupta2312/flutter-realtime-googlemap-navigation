import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_live_tracking/map/map_view.dart';
import 'package:flutter_map_live_tracking/util/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  MapScreenController createState() => MapScreenController();
}

class MapScreenController extends State<MapScreen> {
  @override
  Widget build(BuildContext context) => MapView(this);

  LatLng initialPosition = LatLng(0, 0);
  Timer timer;
  String polylineString =
      "cvkjCwggmOTBDa@@g@C_@J{@Fo@Lg@\\c@n@o@Zk@Lg@ZiA|@yBn@_DRcBPaAh@{Bn@}B^u@XaAlK|"
      "B~HdBlAh@nD|BzHxEtBlA~@l@zA~@hAl@`GrCnK`FnAj@ZTR^\\p@d@dAvAnDn@`BxAxDbAzCjAlEx@v"
      "CdCrIzCdMHZD`@?R?DpBl@`A`@\\J`ARXDzMfE~@TDCFCLARFJP@LAPQRQBE?Oh@YpAc@bCC^Bn@^r@Vh@"
      "Tl@Df@Cl@Iv@WtAKfA@xBLnCHVJPPPrDdCtFrDTHPHDTf@b@n@d@tCtBnBhA|@_@?A@A@EHCF?FDBHAHbA?d"
      "Ik@zFi@ZOXGf@K~Ea@bEc@rBe@@IBKPMR?LJFT?JKNQFKA";

  Polyline polyline;
  List<LatLng> polyLinePoints = List<LatLng>();
  Completer completer = Completer();
  Marker startMarker, endMarker, movingMarker;
  bool playing = false;
  int _currentMarkerIndex = 0;
  double zoom = 15;
  static const double TILT = 20;

  @override
  void initState() {
    initializeTimer();
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    timer = null;
    super.dispose();
  }

  void initializeMapComponents() async {
    await calculatePolyLines();
    startMarker = Marker(
        markerId: MarkerId("0"),
        position: polyLinePoints[0],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
    endMarker = Marker(
        markerId: MarkerId("1"),
        position: polyLinePoints[polyLinePoints.length - 1],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed));

    var bearing = Utils.calculateHeading(
        polyLinePoints[0].latitude,
        polyLinePoints[0].longitude,
        polyLinePoints[1].latitude,
        polyLinePoints[1].longitude);

    movingMarker = Marker(
      markerId: MarkerId("01"),
      position: polyLinePoints[0],
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
    );

    var bounds = await Utils.boundsFromLatLngList(polyLinePoints);
    if (!mounted) return;
    setState(() {});

    await Future.delayed(Duration(seconds: 2));
    GoogleMapController controller = await completer.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 20));
    await Future.delayed(Duration(seconds: 2));
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(polyLinePoints[0].latitude, polyLinePoints[0].longitude),
        bearing: bearing,
        tilt: TILT,
        zoom: zoom)));
  }

  /// This method converts custom image to BitmapDescriptor which is needed for Map Marker Icon
  Future<BitmapDescriptor> getCustomMarker() {
    return BitmapDescriptor.fromAssetImage(
      ImageConfiguration(),
      "assets/icons/green-car-marker.png",
    );
  }

  calculatePolyLines() async {
    var points = await Utils.decodeEncodedPolyline(polylineString);
    print("points:${points.length}");
    polyLinePoints = await Utils.getFineData(points);
    print("points:${polyLinePoints.length}");
    polyline = Polyline(
        polylineId: PolylineId("0"),
        points: polyLinePoints,
        color: Colors.black54,
        width: 3);
  }

  void initializeTimer() {
    timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      if (timer.isActive && playing) {
        if (_currentMarkerIndex < polyLinePoints.length - 1)
          updateMarkerPosition();
        else {
          resetState();
        }
      }
    });
  }

  void manageMarkerMovement() {
    if (mounted) {
      setState(() {
        playing = !playing;
      });
    }
  }

  void updateMarkerPosition() async {
    GoogleMapController controller = await completer.future;
    await controller.getVisibleRegion();
    LatLng current = polyLinePoints[_currentMarkerIndex];
    LatLng next = polyLinePoints[_currentMarkerIndex + 1];

    var bearing = Utils.calculateHeading(
        current.latitude, current.latitude, next.latitude, next.longitude);

    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        bearing: bearing, target: next, zoom: zoom, tilt: TILT)));

    var updatedMarker = movingMarker.copyWith(positionParam: next);

    setState(() {
      movingMarker = updatedMarker;
    });
    _currentMarkerIndex++;
  }

  void resetState() {
    polyLinePoints.clear();
    _currentMarkerIndex = 0;
    initializeMapComponents();
  }
}
