import 'package:flutter_test/flutter_test.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/core/utils/debouncer.dart';
import 'package:teste_spixs/features/home/controllers/home_controller.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/home/domain/entities/place_prediction.dart';
import 'package:teste_spixs/features/home/domain/repositories/places_repository.dart';

class _FakePlacesRepository implements PlacesRepository {
  _FakePlacesRepository(this.details);

  final PlaceDetails details;
  String? lastPlaceId;

  @override
  Future<PlaceDetails> getDetails(
    String placeId, {
    required String sessionToken,
  }) async {
    lastPlaceId = placeId;
    return details;
  }

  @override
  Future<List<PlacePrediction>> search(
    String query, {
    required String sessionToken,
    double? latitude,
    double? longitude,
  }) async =>
      const [];
}

void main() {
  const details = PlaceDetails(
    placeId: 'abc',
    address: 'Av. Paulista, 1000',
    latitude: -23.56,
    longitude: -46.65,
  );

  test('starts with 3 points and can add more', () {
    final controller = HomeController(
      placesRepository: _FakePlacesRepository(details),
      locationPermissionService: LocationPermissionService(),
      searchDebouncer: Debouncer(delay: Duration.zero),
    )..onInit();

    expect(controller.points, hasLength(3));
    controller.addPoint();
    expect(controller.points, hasLength(4));
    expect(controller.points.last.label, 'Ponto D');
    controller.onClose();
  });

  test('can remove extra points and relabels the rest', () {
    final controller = HomeController(
      placesRepository: _FakePlacesRepository(details),
      locationPermissionService: LocationPermissionService(),
      searchDebouncer: Debouncer(delay: Duration.zero),
    )..onInit();

    controller.addPoint();
    controller.addPoint();
    expect(controller.points.map((field) => field.label), [
      'Ponto A',
      'Ponto B',
      'Ponto C',
      'Ponto D',
      'Ponto E',
    ]);

    controller.removePoint(3);
    expect(controller.points, hasLength(4));
    expect(controller.points[3].label, 'Ponto D');

    controller.removePoint(0);
    expect(controller.points, hasLength(4));
    controller.onClose();
  });

  test('selecting 3 places enables confirm', () async {
    final repository = _FakePlacesRepository(details);
    final controller = HomeController(
      placesRepository: repository,
      locationPermissionService: LocationPermissionService(),
      searchDebouncer: Debouncer(delay: Duration.zero),
    )..onInit();

    const prediction = PlacePrediction(
      placeId: 'abc',
      description: 'Av. Paulista, 1000',
    );

    await controller.selectPrediction(0, prediction);
    await controller.selectPrediction(1, prediction);
    expect(controller.canConfirm.value, isFalse);
    await controller.selectPrediction(2, prediction);

    expect(controller.canConfirm.value, isTrue);
    expect(repository.lastPlaceId, 'abc');

    final plan = controller.createRoutePlan();
    expect(plan, isNotNull);
    expect(plan!.stops, hasLength(3));
    controller.onClose();
  });

  test('asks to pick a suggestion when the text was not selected', () {
    final controller = HomeController(
      placesRepository: _FakePlacesRepository(details),
      locationPermissionService: LocationPermissionService(),
      searchDebouncer: Debouncer(delay: Duration.zero),
    )..onInit();

    controller.points[0].textController.text = 'rua das azaleias';
    expect(controller.createRoutePlan(), isNull);
    expect(controller.points[0].error, 'Selecione um endereço da lista');
    expect(controller.points[1].error, 'Campo obrigatório');
    controller.onClose();
  });
}
