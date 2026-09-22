import 'package:teste_spixs/core/errors/app_exception.dart';
import 'package:teste_spixs/core/network/app_http_client.dart';

class PlacesApiService {
  PlacesApiService({
    required AppHttpClient client,
    required String apiKey,
  }) : _client = client,
       _apiKey = apiKey;

  static const _authority = 'places.googleapis.com';

  final AppHttpClient _client;
  final String _apiKey;

  Future<Map<String, dynamic>> autocomplete({
    required String input,
    required String sessionToken,
    double? latitude,
    double? longitude,
  }) {
    final body = <String, dynamic>{
      'input': input,
      'languageCode': 'pt-BR',
      'sessionToken': sessionToken,
    };

    if (latitude != null && longitude != null) {
      final center = {'latitude': latitude, 'longitude': longitude};
      body['origin'] = center;
      body['locationBias'] = {
        'circle': {
          'center': center,
          'radius': 50000.0,
        },
      };
    }

    return _mapErrors(
      () => _client.post(
        Uri.https(_authority, '/v1/places:autocomplete'),
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat,suggestions.placePrediction.distanceMeters',
        },
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> details({
    required String placeId,
    required String sessionToken,
  }) {
    return _mapErrors(
      () => _client.get(
        Uri.https(_authority, '/v1/places/$placeId', {
          'sessionToken': sessionToken,
          'languageCode': 'pt-BR',
        }),
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'id,formattedAddress,location',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _mapErrors(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on NetworkException catch (error) {
      throw PlacesException(error.message, cause: error);
    }
  }
}
