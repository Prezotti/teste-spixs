import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:teste_spixs/core/errors/app_exception.dart';
import 'package:teste_spixs/core/network/app_http_client.dart';
import 'package:teste_spixs/features/home/data/repositories/places_repository_impl.dart';
import 'package:teste_spixs/features/home/data/services/places_api_service.dart';

void main() {
  PlacesRepositoryImpl repositoryWith(
    Map<String, dynamic> body, {
    int statusCode = 200,
  }) {
    final client = AppHttpClient(
      client: MockClient(
        (_) async => http.Response(jsonEncode(body), statusCode),
      ),
    );
    return PlacesRepositoryImpl(
      PlacesApiService(client: client, apiKey: 'test-key'),
    );
  }

  test('search maps Places API (New) suggestions to entities', () async {
    final repository = repositoryWith({
      'suggestions': [
        {
          'placePrediction': {
            'placeId': 'abc',
            'text': {'text': 'Av. Paulista, 1000 - São Paulo'},
            'structuredFormat': {
              'mainText': {'text': 'Av. Paulista, 1000'},
              'secondaryText': {'text': 'São Paulo'},
            },
            'distanceMeters': 800,
          },
        },
      ],
    });

    final result = await repository.search(
      'Paulista',
      sessionToken: 'token',
    );

    expect(result, hasLength(1));
    expect(result.first.placeId, 'abc');
    expect(result.first.mainText, 'Av. Paulista, 1000');
  });

  test('search returns empty when Google has no suggestions', () async {
    final repository = repositoryWith({});

    final result = await repository.search(
      'xyzxyz',
      sessionToken: 'token',
    );

    expect(result, isEmpty);
  });

  test('search throws when API key is denied', () async {
    final repository = repositoryWith({
      'error': {
        'code': 403,
        'message': 'Legacy API is not enabled.',
        'status': 'PERMISSION_DENIED',
      },
    }, statusCode: 403);

    expect(
      () => repository.search('Paulista', sessionToken: 'token'),
      throwsA(isA<PlacesException>()),
    );
  });

  test('getDetails maps coordinates and address', () async {
    final repository = repositoryWith({
      'id': 'abc',
      'formattedAddress': 'Av. Paulista, 1000 - São Paulo',
      'location': {'latitude': -23.561, 'longitude': -46.656},
    });

    final details = await repository.getDetails('abc', sessionToken: 'token');

    expect(details.address, contains('Paulista'));
    expect(details.latitude, -23.561);
    expect(details.longitude, -46.656);
  });
}
