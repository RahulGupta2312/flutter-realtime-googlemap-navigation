import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as MP;
import 'package:vector_math/vector_math.dart';

class Utils {
  static const num earthRadius = 6371009.0;
  static String mapStyles = '''[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]''';

  static Future<num> computeLength(List<LatLng> path) async {
    if (path.length < 2) {
      return 0;
    }

    final prev = path.first;
    var prevLat = radians(prev.latitude);
    var prevLng = radians(prev.longitude);

    final length = path.fold<num>(0.0, (value, point) {
      final lat = radians(point.latitude);
      final lng = radians(point.longitude);
      value += distanceRadians(prevLat, prevLng, lat, lng);
      prevLat = lat;
      prevLng = lng;

      return value;
    });

    return length * earthRadius;
  }

  static double calculateHeading(
      double lat1, double lng1, double lat2, double lng2) {
    return MP.SphericalUtil.computeHeading(
        MP.LatLng(lat1, lng1), MP.LatLng(lat2, lng2));
  }

  static double calculateDistance(lat1, lng1, lat2, lng2) {
    return MP.SphericalUtil.computeDistanceBetween(
        MP.LatLng(lat1, lng1), MP.LatLng(lat2, lng2));
  }

  static MP.LatLng interpolate(lat1, lng1, lat2, lng2, fraction) {
    return MP.SphericalUtil.interpolate(
        MP.LatLng(lat1, lng1), MP.LatLng(lat2, lng2), fraction);
  }
  static num arcHav(num x) => 2 * asin(sqrt(x));

  static num havDistance(num lat1, num lat2, num dLng) =>
      hav(lat1 - lat2) + hav(dLng) * cos(lat1) * cos(lat2);

  /// Returns distance on the unit sphere; the arguments are in radians.
  static num distanceRadians(num lat1, num lng1, num lat2, num lng2) =>
      arcHav(havDistance(lat1, lat2, lng1 - lng2));

  /// Returns haversine(angle-in-radians).
  /// hav(x) == (1 - cos(x)) / 2 == sin(x / 2)^2.
  static num hav(num x) => sin(x * 0.5) * sin(x * 0.5);

  static Future<LatLngBounds> boundsFromLatLngList(List<LatLng> list) async {
    assert(list.isNotEmpty);
    double x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1) y1 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  static Future<List<LatLng>> decodeEncodedPolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      LatLng p = new LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return Future.value(poly);
  }

  static Future<List<LatLng>> getFineData(List<LatLng> roughData) async {
    List<LatLng> fineData = List<LatLng>();
    LatLng latLngA, latLngB;
    var steps, step;

    num distance = await computeLength(roughData);
    int duration = 1200;
    double speed = distance / duration;
    int fps = 20;
    var resolution = speed * (1 / fps);

    for (var i = 1; i < roughData.length; i++) {
      latLngA = LatLng(roughData[i - 1].latitude, roughData[i - 1].longitude);
      latLngB = LatLng(roughData[i].latitude, roughData[i].longitude);
      var distanceDiff = Utils.calculateDistance(latLngA.latitude,
          latLngA.longitude, latLngB.latitude, latLngB.longitude);
      steps = (distanceDiff / resolution).ceil();
      step = 1 / steps;
//      print("steps: $steps");
      var previousInterpolatedLatLng = latLngA;
      for (var j = 1; j < steps; j++) {
        var interpolated = Utils.interpolate(latLngA.latitude,
            latLngA.longitude, latLngB.latitude, latLngB.longitude, step * j);
        fineData.add(LatLng(interpolated.latitude, interpolated.longitude));
      }
    }
    return fineData;
  }
}
