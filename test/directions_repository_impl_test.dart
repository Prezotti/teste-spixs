import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:teste_spixs/core/errors/app_exception.dart';
import 'package:teste_spixs/core/network/app_http_client.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/route/data/repositories/directions_repository_impl.dart';
import 'package:teste_spixs/features/route/data/services/routes_api_service.dart';

void main() {
  const stopA = PlaceDetails(
    placeId: 'a',
    address: 'Rua A',
    latitude: -23.56,
    longitude: -46.65,
  );
  const stopB = PlaceDetails(
    placeId: 'b',
    address: 'Rua B',
    latitude: -23.57,
    longitude: -46.64,
  );

  DirectionsRepositoryImpl repositoryWith(
    Map<String, dynamic> body, {
    int statusCode = 200,
  }) {
    final client = AppHttpClient(
      client: MockClient(
        (_) async => http.Response(jsonEncode(body), statusCode),
      ),
    );
    return DirectionsRepositoryImpl(
      RoutesApiService(client: client, apiKey: 'test-key'),
    );
  }

  Map<String, dynamic> okRoute({
    required List<int> waypointOrder,
    required List<int> distances,
    required List<int> durations,
  }) {
    return {
      'routes': [
        {
          'optimizedIntermediateWaypointIndex': waypointOrder,
          'distanceMeters': distances.fold<int>(0, (sum, value) => sum + value),
          'duration': '${durations.fold<int>(0, (sum, value) => sum + value)}s',
          'legs': [
            for (var i = 0; i < distances.length; i++)
              {
                'distanceMeters': distances[i],
                'duration': '${durations[i]}s',
                'polyline': {
                  'encodedPolyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
                },
                if (i == 0)
                  'steps': [
                    {
                      'navigationInstruction': {
                        'maneuver': 'TURN_RIGHT',
                        'instructions': 'Vire à direita na R. Augusta',
                      },
                      'endLocation': {
                        'latLng': {'latitude': -23.551, 'longitude': -46.651},
                      },
                    },
                  ],
              },
          ],
        },
      ],
    };
  }

  test('reorders stops by Routes API order and drops the return leg', () async {
    final repository = repositoryWith(
      okRoute(
        waypointOrder: [1, 0],
        distances: [1000, 2000, 9999],
        durations: [120, 240, 999],
      ),
    );

    final route = await repository.optimize(
      stops: [stopA, stopB],
      originLatitude: -23.55,
      originLongitude: -46.66,
    );

    expect(route.stops.map((stop) => stop.place.placeId), ['b', 'a']);
    expect(route.stops.map((stop) => stop.number), [2, 3]);
    expect(route.origin, isNotNull);
    expect(route.distanceMeters, 3000);
    expect(route.durationSeconds, 360);
    expect(route.polyline, isNotEmpty);
    expect(route.stops.first.legDistanceMeters, 1000);
    expect(route.stops.first.legDurationSeconds, 120);
    expect(route.maneuvers, hasLength(1));
    expect(route.maneuvers.first.instruction, 'Vire à direita na R. Augusta');
    expect(route.maneuvers.first.maneuver, 'TURN_RIGHT');
  });

  test('keeps the first stop as start when there is no origin', () async {
    final repository = repositoryWith(
      okRoute(
        waypointOrder: [0],
        distances: [1500, 8000],
        durations: [180, 900],
      ),
    );

    final route = await repository.optimize(stops: [stopA, stopB]);

    expect(route.stops.map((stop) => stop.place.placeId), ['a', 'b']);
    expect(route.origin, isNull);
    expect(route.distanceMeters, 1500);
    expect(route.durationSeconds, 180);
  });

  test('throws when Routes API denies the request', () async {
    final repository = repositoryWith({
      'error': {
        'code': 403,
        'message': 'Routes API is not enabled.',
        'status': 'PERMISSION_DENIED',
      },
    }, statusCode: 403);

    expect(
      () => repository.optimize(
        stops: [stopA, stopB],
        originLatitude: -23.55,
        originLongitude: -46.66,
      ),
      throwsA(isA<DirectionsException>()),
    );
  });
}
