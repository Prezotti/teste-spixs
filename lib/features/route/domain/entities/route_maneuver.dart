import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';

class RouteManeuver {
  const RouteManeuver({
    required this.instruction,
    required this.maneuver,
    required this.end,
  });

  final String instruction;
  final String maneuver;
  final GeoPoint end;
}
