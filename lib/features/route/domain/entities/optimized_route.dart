import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';
import 'package:teste_spixs/features/route/domain/entities/route_stop.dart';

class OptimizedRoute {
  const OptimizedRoute({
    this.origin,
    required this.stops,
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final GeoPoint? origin;
  final List<RouteStop> stops;
  final List<GeoPoint> polyline;
  final int distanceMeters;
  final int durationSeconds;
}
