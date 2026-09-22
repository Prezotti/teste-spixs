import 'package:teste_spixs/core/errors/app_exception.dart';
import 'package:teste_spixs/features/home/data/services/places_api_service.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/home/domain/entities/place_prediction.dart';
import 'package:teste_spixs/features/home/domain/repositories/places_repository.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl(this._service);

  final PlacesApiService _service;

  @override
  Future<List<PlacePrediction>> search(
    String query, {
    required String sessionToken,
    double? latitude,
    double? longitude,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    final json = await _service.autocomplete(
      input: trimmed,
      sessionToken: sessionToken,
      latitude: latitude,
      longitude: longitude,
    );

    final suggestions = json['suggestions'] as List<dynamic>? ?? const [];
    final predictions = suggestions
        .whereType<Map<String, dynamic>>()
        .map(_predictionFromJson)
        .where((prediction) => prediction.placeId.isNotEmpty)
        .toList();

    predictions.sort((left, right) {
      final leftDistance = left.distanceMeters ?? 1 << 30;
      final rightDistance = right.distanceMeters ?? 1 << 30;
      return leftDistance.compareTo(rightDistance);
    });

    return predictions;
  }

  @override
  Future<PlaceDetails> getDetails(
    String placeId, {
    required String sessionToken,
  }) async {
    final json = await _service.details(
      placeId: placeId,
      sessionToken: sessionToken,
    );

    final location = json['location'] as Map<String, dynamic>?;
    final lat = (location?['latitude'] as num?)?.toDouble();
    final lng = (location?['longitude'] as num?)?.toDouble();
    final address = json['formattedAddress'] as String?;

    if (lat == null || lng == null || address == null) {
      throw const PlacesException(
        'Não foi possível obter os dados do endereço.',
      );
    }

    return PlaceDetails(
      placeId: json['id'] as String? ?? placeId,
      address: address,
      latitude: lat,
      longitude: lng,
    );
  }

  PlacePrediction _predictionFromJson(Map<String, dynamic> json) {
    final prediction = json['placePrediction'] as Map<String, dynamic>?;
    final structured = prediction?['structuredFormat'] as Map<String, dynamic>?;
    return PlacePrediction(
      placeId: prediction?['placeId'] as String? ?? '',
      description: prediction?['text']?['text'] as String? ?? '',
      mainText: structured?['mainText']?['text'] as String?,
      secondaryText: structured?['secondaryText']?['text'] as String?,
      distanceMeters: (prediction?['distanceMeters'] as num?)?.toInt(),
    );
  }
}
