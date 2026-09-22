import 'package:teste_spixs/features/home/domain/entities/place_details.dart';

class RoutePlanArgs {
  const RoutePlanArgs({
    required this.stops,
    this.originLatitude,
    this.originLongitude,
  });

  final List<PlaceDetails> stops;
  final double? originLatitude;
  final double? originLongitude;

  bool get hasOrigin => originLatitude != null && originLongitude != null;
}
