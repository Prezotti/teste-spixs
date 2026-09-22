import 'package:flutter_test/flutter_test.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';
import 'package:teste_spixs/features/route/domain/entities/route_stop.dart';
import 'package:teste_spixs/features/route/domain/route_progress.dart';

void main() {
  const line = [
    GeoPoint(0, 0),
    GeoPoint(0, 0.001),
  ];
  const stop = RouteStop(
    number: 1,
    place: PlaceDetails(
      placeId: 'stop-1',
      address: 'Parada',
      latitude: 0,
      longitude: 0,
    ),
  );

  test('stays on route when the position is on the polyline', () {
    final progress = RouteProgressEvaluator.evaluate(
      position: const GeoPoint(0, 0.0005),
      polyline: line,
      stops: const [stop],
      alreadyVisited: const {},
    );

    expect(progress.offRoute, isFalse);
    expect(progress.visitedPlaceIds, isEmpty);
  });

  test('marks a stop visited when the user is close to it', () {
    final progress = RouteProgressEvaluator.evaluate(
      position: const GeoPoint(0.0002, 0),
      polyline: line,
      stops: const [stop],
      alreadyVisited: const {},
    );

    expect(progress.visitedPlaceIds, {'stop-1'});
  });

  test('detects a deviation beyond the threshold', () {
    final progress = RouteProgressEvaluator.evaluate(
      position: const GeoPoint(0.002, 0),
      polyline: line,
      stops: const [stop],
      alreadyVisited: const {'stop-1'},
    );

    expect(progress.offRoute, isTrue);
    expect(
      RouteProgressEvaluator.distanceToPolylineMeters(
        const GeoPoint(0.002, 0),
        line,
      ),
      greaterThan(RouteProgressEvaluator.deviationThresholdMeters),
    );
  });

  test('rejects a GPS fix less accurate than 100 meters', () {
    expect(RouteProgressEvaluator.acceptsFix(100), isTrue);
    expect(RouteProgressEvaluator.acceptsFix(101), isFalse);
  });
}
