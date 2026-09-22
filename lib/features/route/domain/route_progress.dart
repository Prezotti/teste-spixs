import 'dart:math' as math;

import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';
import 'package:teste_spixs/features/route/domain/entities/route_stop.dart';

class RouteProgress {
  const RouteProgress({
    required this.visitedPlaceIds,
    required this.offRoute,
  });

  final Set<String> visitedPlaceIds;
  final bool offRoute;
}

abstract final class RouteProgressEvaluator {
  static const deviationThresholdMeters = 80.0;
  static const arrivalThresholdMeters = 45.0;

  static RouteProgress evaluate({
    required GeoPoint position,
    required List<GeoPoint> polyline,
    required List<RouteStop> stops,
    required Set<String> alreadyVisited,
  }) {
    final visited = {...alreadyVisited};
    for (final stop in stops) {
      if (visited.contains(stop.place.placeId)) continue;
      final distance = distanceMeters(
        position,
        GeoPoint(stop.place.latitude, stop.place.longitude),
      );
      if (distance <= arrivalThresholdMeters) {
        visited.add(stop.place.placeId);
      }
    }

    final offRoute =
        polyline.isNotEmpty &&
        distanceToPolylineMeters(position, polyline) > deviationThresholdMeters;

    return RouteProgress(visitedPlaceIds: visited, offRoute: offRoute);
  }

  static double distanceMeters(GeoPoint from, GeoPoint to) {
    const earthRadius = 6371000.0;
    final dLat = _rad(to.latitude - from.latitude);
    final dLng = _rad(to.longitude - from.longitude);
    final lat1 = _rad(from.latitude);
    final lat2 = _rad(to.latitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(h)));
  }

  static double distanceToPolylineMeters(GeoPoint point, List<GeoPoint> polyline) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) return distanceMeters(point, polyline.first);

    var nearest = double.infinity;
    for (var i = 0; i < polyline.length - 1; i++) {
      final distance = _distanceToSegmentMeters(point, polyline[i], polyline[i + 1]);
      if (distance < nearest) nearest = distance;
    }
    return nearest;
  }

  static double _distanceToSegmentMeters(GeoPoint point, GeoPoint start, GeoPoint end) {
    final lngScale = 111320.0 * math.cos(_rad(point.latitude));
    const latScale = 111320.0;

    double east(GeoPoint value) => (value.longitude - point.longitude) * lngScale;
    double north(GeoPoint value) => (value.latitude - point.latitude) * latScale;

    final startEast = east(start);
    final startNorth = north(start);
    final deltaEast = east(end) - startEast;
    final deltaNorth = north(end) - startNorth;
    final lengthSquared = deltaEast * deltaEast + deltaNorth * deltaNorth;
    if (lengthSquared == 0) {
      return math.sqrt(startEast * startEast + startNorth * startNorth);
    }

    final projection =
        ((-startEast) * deltaEast + (-startNorth) * deltaNorth) / lengthSquared;
    final clamped = projection.clamp(0.0, 1.0);
    final closestEast = startEast + deltaEast * clamped;
    final closestNorth = startNorth + deltaNorth * clamped;
    return math.sqrt(closestEast * closestEast + closestNorth * closestNorth);
  }

  static double _rad(double degrees) => degrees * math.pi / 180;
}
