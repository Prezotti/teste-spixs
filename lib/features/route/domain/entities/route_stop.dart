import 'package:teste_spixs/features/home/domain/entities/place_details.dart';

class RouteStop {
  const RouteStop({
    required this.number,
    required this.place,
    this.legDistanceMeters = 0,
    this.legDurationSeconds = 0,
  });

  final int number;
  final PlaceDetails place;
  final int legDistanceMeters;
  final int legDurationSeconds;
}
