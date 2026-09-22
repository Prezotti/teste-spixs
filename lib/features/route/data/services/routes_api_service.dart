import 'package:teste_spixs/core/errors/app_exception.dart';
import 'package:teste_spixs/core/network/app_http_client.dart';
import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';

class RoutesApiService {
  RoutesApiService({
    required AppHttpClient client,
    required String apiKey,
  }) : _client = client,
       _apiKey = apiKey;

  static const _authority = 'routes.googleapis.com';

  final AppHttpClient _client;
  final String _apiKey;

  Future<Map<String, dynamic>> computeRoutes({
    required GeoPoint origin,
    required GeoPoint destination,
    required List<GeoPoint> intermediates,
  }) {
    return _mapErrors(
      () => _client.post(
        Uri.https(_authority, '/directions/v2:computeRoutes'),
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.optimizedIntermediateWaypointIndex,routes.legs.duration,routes.legs.distanceMeters,routes.legs.polyline.encodedPolyline',
        },
        body: {
          'origin': _waypoint(origin),
          'destination': _waypoint(destination),
          'intermediates': [
            for (final point in intermediates) _waypoint(point),
          ],
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_UNAWARE',
          'optimizeWaypointOrder': true,
          'languageCode': 'pt-BR',
          'units': 'METRIC',
        },
      ),
    );
  }

  Map<String, dynamic> _waypoint(GeoPoint point) {
    return {
      'location': {
        'latLng': {
          'latitude': point.latitude,
          'longitude': point.longitude,
        },
      },
    };
  }

  Future<Map<String, dynamic>> _mapErrors(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on NetworkException catch (error) {
      throw DirectionsException(error.message, cause: error);
    }
  }
}
