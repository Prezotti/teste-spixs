import 'package:teste_spixs/features/home/domain/entities/place_details.dart';

class RouteStop {
  const RouteStop({
    required this.number,
    required this.place,
  });

  final int number;
  final PlaceDetails place;
}
