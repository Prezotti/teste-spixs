import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';

abstract final class PolylineDecoder {
  static List<GeoPoint> decode(String encoded) {
    final points = <GeoPoint>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      final dlat = _next(encoded, index);
      index = dlat.index;
      lat += dlat.value;

      final dlng = _next(encoded, index);
      index = dlng.index;
      lng += dlng.value;

      points.add(GeoPoint(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  static ({int value, int index}) _next(String encoded, int index) {
    var result = 0;
    var shift = 0;
    var cursor = index;
    var bits = 0;

    do {
      bits = encoded.codeUnitAt(cursor++) - 63;
      result |= (bits & 0x1f) << shift;
      shift += 5;
    } while (bits >= 0x20);

    final value = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    return (value: value, index: cursor);
  }
}
