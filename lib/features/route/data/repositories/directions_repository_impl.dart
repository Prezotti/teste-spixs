import 'package:teste_spixs/core/errors/app_exception.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/route/data/polyline_decoder.dart';
import 'package:teste_spixs/features/route/data/services/routes_api_service.dart';
import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';
import 'package:teste_spixs/features/route/domain/entities/optimized_route.dart';
import 'package:teste_spixs/features/route/domain/entities/route_stop.dart';
import 'package:teste_spixs/features/route/domain/repositories/directions_repository.dart';

class DirectionsRepositoryImpl implements DirectionsRepository {
  DirectionsRepositoryImpl(this._service);

  final RoutesApiService _service;

  @override
  Future<OptimizedRoute> optimize({
    required List<PlaceDetails> stops,
    double? originLatitude,
    double? originLongitude,
  }) async {
    if (stops.length < 2) {
      throw const DirectionsException(
        'Adicione pelo menos 2 endereços para traçar a rota.',
      );
    }

    final hasOrigin = originLatitude != null && originLongitude != null;
    final origin = hasOrigin
        ? GeoPoint(originLatitude, originLongitude)
        : GeoPoint(stops.first.latitude, stops.first.longitude);
    final waypointStops = hasOrigin ? stops : stops.sublist(1);

    if (waypointStops.isEmpty) {
      throw const DirectionsException(
        'Adicione pelo menos 2 endereços para traçar a rota.',
      );
    }

    final json = await _service.computeRoutes(
      origin: origin,
      destination: origin,
      intermediates: [
        for (final stop in waypointStops)
          GeoPoint(stop.latitude, stop.longitude),
      ],
    );

    final routes = json['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      throw const DirectionsException(
        'Não encontramos uma rota entre esses pontos.',
      );
    }

    final route = routes.first as Map<String, dynamic>;
    final order = (route['optimizedIntermediateWaypointIndex'] as List<dynamic>?)
            ?.map((index) => (index as num).toInt())
            .toList() ??
        List<int>.generate(waypointStops.length, (index) => index);

    final orderedWaypoints = [
      for (final index in order)
        if (index >= 0 && index < waypointStops.length) waypointStops[index],
    ];

    if (orderedWaypoints.length != waypointStops.length) {
      throw const DirectionsException(
        'Não foi possível otimizar a ordem dos pontos.',
      );
    }

    final orderedStops = hasOrigin
        ? orderedWaypoints
        : [stops.first, ...orderedWaypoints];

    final legs = route['legs'] as List<dynamic>? ?? const [];
    final travelLegs = legs
        .take(waypointStops.length)
        .whereType<Map<String, dynamic>>();

    var distanceMeters = 0;
    var durationSeconds = 0;
    final polyline = <GeoPoint>[];

    for (final leg in travelLegs) {
      distanceMeters += (leg['distanceMeters'] as num?)?.toInt() ?? 0;
      durationSeconds += _parseDuration(leg['duration']);

      final encoded = leg['polyline']?['encodedPolyline'] as String?;
      if (encoded == null || encoded.isEmpty) continue;
      polyline.addAll(PolylineDecoder.decode(encoded));
    }

    if (polyline.isEmpty) {
      final encoded = route['polyline']?['encodedPolyline'] as String?;
      if (encoded != null && encoded.isNotEmpty) {
        polyline.addAll(PolylineDecoder.decode(encoded));
      }
    }

    if (polyline.isEmpty) {
      throw const DirectionsException(
        'A rota veio sem o traçado no mapa. Tente novamente.',
      );
    }

    if (distanceMeters == 0) {
      distanceMeters = (route['distanceMeters'] as num?)?.toInt() ?? 0;
    }
    if (durationSeconds == 0) {
      durationSeconds = _parseDuration(route['duration']);
    }

    return OptimizedRoute(
      origin: hasOrigin ? origin : null,
      stops: [
        for (var i = 0; i < orderedStops.length; i++)
          RouteStop(number: i + 1, place: orderedStops[i]),
      ],
      polyline: polyline,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  }

  int _parseDuration(Object? value) {
    if (value is num) return value.round();
    if (value is! String || value.isEmpty) return 0;
    final raw = value.endsWith('s') ? value.substring(0, value.length - 1) : value;
    return double.tryParse(raw)?.round() ?? 0;
  }
}
