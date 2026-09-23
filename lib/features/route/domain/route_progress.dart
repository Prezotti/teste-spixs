import 'dart:math' as math;

import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';
import 'package:teste_spixs/features/route/domain/entities/route_maneuver.dart';
import 'package:teste_spixs/features/route/domain/entities/route_stop.dart';

class RouteProgress {
  const RouteProgress({
    required this.visitedPlaceIds,
    required this.offRoute,
  });

  final Set<String> visitedPlaceIds;
  final bool offRoute;
}

class PolylineSlice {
  const PolylineSlice({required this.points, required this.segmentIndex});

  final List<GeoPoint> points;
  final int segmentIndex;
}

abstract final class RouteProgressEvaluator {
  static const deviationThresholdMeters = 40.0;
  static const arrivalThresholdMeters = 20.0;
  static const stepArrivalMeters = 35.0;
  static const maxAccuracyMeters = 100.0;
  static const trailSnapMeters = 50.0;
  static const trailLookaheadMeters = 250.0;

  static bool acceptsFix(double accuracyMeters) => accuracyMeters <= maxAccuracyMeters;

  static int activeManeuverIndex({
    required GeoPoint position,
    required List<RouteManeuver> maneuvers,
    required int currentIndex,
  }) {
    if (maneuvers.isEmpty) return 0;
    var index = currentIndex.clamp(0, maneuvers.length - 1);
    while (index < maneuvers.length - 1) {
      final toCurrent = distanceMeters(position, maneuvers[index].end);
      if (toCurrent <= stepArrivalMeters) {
        index++;
        continue;
      }
      final toNext = distanceMeters(position, maneuvers[index + 1].end);
      if (toNext <= toCurrent) {
        index++;
        continue;
      }
      break;
    }
    return index;
  }

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
      final distance = _closestOnSegment(point, polyline[i], polyline[i + 1]).distance;
      if (distance < nearest) nearest = distance;
    }
    return nearest;
  }

  static PolylineSlice trimTraveled({
    required GeoPoint position,
    required List<GeoPoint> polyline,
    required int fromSegment,
  }) {
    if (polyline.length < 2) {
      return PolylineSlice(points: polyline, segmentIndex: 0);
    }

    final start = fromSegment.clamp(0, polyline.length - 2);
    var bestIndex = start;
    var bestDistance = double.infinity;
    var bestPoint = polyline[start];
    var along = 0.0;

    for (var i = start; i < polyline.length - 1; i++) {
      final hit = _closestOnSegment(position, polyline[i], polyline[i + 1]);
      if (hit.distance < bestDistance) {
        bestDistance = hit.distance;
        bestIndex = i;
        bestPoint = hit.point;
      }
      along += distanceMeters(polyline[i], polyline[i + 1]);
      if (along >= trailLookaheadMeters) break;
    }

    final onTrail = bestDistance <= trailSnapMeters;
    final segmentIndex = onTrail ? bestIndex : start;
    final anchor = onTrail
        ? bestPoint
        : _closestOnSegment(position, polyline[start], polyline[start + 1]).point;

    return PolylineSlice(
      points: [anchor, ...polyline.sublist(segmentIndex + 1)],
      segmentIndex: segmentIndex,
    );
  }

  static _SegmentHit _closestOnSegment(GeoPoint point, GeoPoint start, GeoPoint end) {
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
      return _SegmentHit(
        distance: math.sqrt(startEast * startEast + startNorth * startNorth),
        point: start,
      );
    }

    final projection =
        ((-startEast) * deltaEast + (-startNorth) * deltaNorth) / lengthSquared;
    final clamped = projection.clamp(0.0, 1.0);
    final closestEast = startEast + deltaEast * clamped;
    final closestNorth = startNorth + deltaNorth * clamped;
    return _SegmentHit(
      distance: math.sqrt(closestEast * closestEast + closestNorth * closestNorth),
      point: GeoPoint(
        start.latitude + (end.latitude - start.latitude) * clamped,
        start.longitude + (end.longitude - start.longitude) * clamped,
      ),
    );
  }

  static double _rad(double degrees) => degrees * math.pi / 180;
}

class _SegmentHit {
  const _SegmentHit({required this.distance, required this.point});

  final double distance;
  final GeoPoint point;
}
