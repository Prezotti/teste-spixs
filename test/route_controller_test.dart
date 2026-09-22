import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:teste_spixs/core/errors/app_exception.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/route/controllers/route_controller.dart';
import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';
import 'package:teste_spixs/features/route/domain/entities/optimized_route.dart';
import 'package:teste_spixs/features/route/domain/entities/route_stop.dart';
import 'package:teste_spixs/features/route/domain/repositories/directions_repository.dart';
import 'package:teste_spixs/features/route/domain/route_plan_args.dart';

class _FakeLocation extends LocationPermissionService {
  _FakeLocation() : granted = true, serviceEnabled = true;

  bool granted;
  bool serviceEnabled;
  final positions = StreamController<Position>.broadcast();

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<bool> request() async => granted;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Stream<Position> watch() => positions.stream;

  @override
  Future<Position?> currentOrLast() async => null;
}

class _FakeDirections implements DirectionsRepository {
  _FakeDirections(this.route, {this.error});

  final OptimizedRoute route;
  final Object? error;
  Completer<OptimizedRoute>? gate;
  var calls = 0;

  @override
  Future<OptimizedRoute> optimize({
    required List<PlaceDetails> stops,
    double? originLatitude,
    double? originLongitude,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    final pending = gate;
    if (pending != null) return pending.future;
    return Future.value(route);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const stopA = PlaceDetails(placeId: 'a', address: 'Rua Augusta, 500', latitude: 0, longitude: 0);
  const stopB = PlaceDetails(placeId: 'b', address: 'R. da Consolação, 930', latitude: 0, longitude: 0.01);

  final sample = OptimizedRoute(
    stops: const [
      RouteStop(number: 1, place: stopA, legDistanceMeters: 2100, legDurationSeconds: 480),
      RouteStop(number: 2, place: stopB, legDistanceMeters: 1800, legDurationSeconds: 360),
    ],
    polyline: const [GeoPoint(0, 0), GeoPoint(0, 0.01)],
    distanceMeters: 3900,
    durationSeconds: 840,
  );

  late _FakeLocation location;
  late _FakeDirections directions;
  late RouteController controller;

  RouteController buildController() {
    return RouteController(
      directionsRepository: directions,
      locationPermissionService: location,
      args: const RoutePlanArgs(stops: [stopA, stopB], originLatitude: 0, originLongitude: 0),
      numberedIcon: (_) async => BitmapDescriptor.defaultMarker,
      arrowIcon: () async => BitmapDescriptor.defaultMarker,
    );
  }

  Future<void> flushNotice(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
  }

  setUp(() {
    location = _FakeLocation();
    directions = _FakeDirections(sample);
    controller = buildController()..route.value = sample;
  });

  tearDown(() {
    controller.onClose();
    location.positions.close();
  });

  Position fix({required double latitude, required double longitude, required double accuracy}) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.utc(2026),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  testWidgets('explains a denied location permission before navigating', (tester) async {
    location.granted = false;

    await controller.startNavigation();

    expect(controller.isNavigating.value, isFalse);
    expect(controller.notice.value, 'Permissão de localização negada. Ative para navegar.');
    expect(directions.calls, 0);
    await flushNotice(tester);
  });

  testWidgets('explains that GPS is off when permission is already granted', (tester) async {
    location.serviceEnabled = false;

    await controller.startNavigation();

    expect(controller.isNavigating.value, isFalse);
    expect(controller.notice.value, 'O GPS do celular está desligado. Ative para navegar.');
    expect(directions.calls, 0);
    await flushNotice(tester);
  });

  testWidgets('ignores an inaccurate fix near a stop', (tester) async {
    await controller.startNavigation();
    location.positions.add(fix(latitude: 0, longitude: 0, accuracy: 80));
    await tester.pump();

    expect(controller.notice.value, 'Sinal de GPS impreciso. Aguardando uma leitura melhor.');
    expect(controller.isRecalculating.value, isFalse);
    expect(directions.calls, 0);
    expect(controller.isNavigating.value, isTrue);
  });

  testWidgets('recalculates after two off-route fixes and announces it', (tester) async {
    await controller.startNavigation();
    final offRoute = fix(latitude: 0.002, longitude: 0.005, accuracy: 8);
    location.positions.add(offRoute);
    location.positions.add(offRoute);
    await tester.pump();
    await tester.pump();

    expect(directions.calls, 1);
    expect(controller.showRecalcBanner.value, isTrue);
    expect(controller.isRecalculating.value, isFalse);
    expect(controller.isNavigating.value, isTrue);
    await flushNotice(tester);
  });

  testWidgets('keeps the recalculating state until the new route arrives', (tester) async {
    final gate = Completer<OptimizedRoute>();
    directions.gate = gate;

    await controller.startNavigation();
    final offRoute = fix(latitude: 0.002, longitude: 0.005, accuracy: 8);
    location.positions.add(offRoute);
    location.positions.add(offRoute);
    await tester.pump();

    expect(controller.isRecalculating.value, isTrue);
    expect(controller.showRecalcBanner.value, isFalse);

    gate.complete(sample);
    await tester.pump();
    await tester.pump();

    expect(controller.isRecalculating.value, isFalse);
    expect(controller.showRecalcBanner.value, isTrue);
    await flushNotice(tester);
  });

  testWidgets('shows the API error when a recalculation fails', (tester) async {
    directions = _FakeDirections(
      sample,
      error: const DirectionsException('Sem internet ou serviço indisponível. Tente novamente.'),
    );
    controller.onClose();
    controller = buildController()..route.value = sample;

    await controller.startNavigation();
    final offRoute = fix(latitude: 0.002, longitude: 0.005, accuracy: 8);
    location.positions.add(offRoute);
    location.positions.add(offRoute);
    await tester.pump();

    expect(controller.notice.value, 'Sem internet ou serviço indisponível. Tente novamente.');
    expect(controller.showRecalcBanner.value, isFalse);
    expect(controller.isRecalculating.value, isFalse);
    expect(controller.isNavigating.value, isTrue);
    await flushNotice(tester);
  });

  testWidgets('shows an error when the first route request fails', (tester) async {
    directions = _FakeDirections(
      sample,
      error: const DirectionsException('Sem internet ou serviço indisponível. Tente novamente.'),
    );
    controller.onClose();
    controller = buildController();

    await controller.loadRoute();

    expect(controller.route.value, isNull);
    expect(controller.errorText.value, 'Sem internet ou serviço indisponível. Tente novamente.');
    expect(controller.isLoading.value, isFalse);
  });
}
