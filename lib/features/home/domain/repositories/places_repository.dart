import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/home/domain/entities/place_prediction.dart';

abstract class PlacesRepository {
  Future<List<PlacePrediction>> search(
    String query, {
    required String sessionToken,
    double? latitude,
    double? longitude,
  });

  Future<PlaceDetails> getDetails(
    String placeId, {
    required String sessionToken,
  });
}
