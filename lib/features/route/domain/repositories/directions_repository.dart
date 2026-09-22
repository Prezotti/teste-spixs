import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/route/domain/entities/optimized_route.dart';

abstract class DirectionsRepository {
  Future<OptimizedRoute> optimize({
    required List<PlaceDetails> stops,
    double? originLatitude,
    double? originLongitude,
  });
}
