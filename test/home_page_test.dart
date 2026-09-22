import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/core/utils/debouncer.dart';
import 'package:teste_spixs/features/home/controllers/home_controller.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/home/domain/entities/place_prediction.dart';
import 'package:teste_spixs/features/home/domain/repositories/places_repository.dart';
import 'package:teste_spixs/features/home/domain/repositories/recent_addresses_repository.dart';
import 'package:teste_spixs/features/home/pages/home_page.dart';

class _EmptyRecents implements RecentAddressesRepository {
  @override
  Future<List<PlaceDetails>> read() async => const [];

  @override
  Future<void> remember(PlaceDetails place) async {}
}

class _EmptyPlaces implements PlacesRepository {
  @override
  Future<PlaceDetails> getDetails(
    String placeId, {
    required String sessionToken,
  }) async {
    return const PlaceDetails(
      placeId: 'x',
      address: 'Rua A',
      latitude: 0,
      longitude: 0,
    );
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
  setUp(() {
    Get.put(
      HomeController(
        placesRepository: _EmptyPlaces(),
        recentAddressesRepository: _EmptyRecents(),
        locationPermissionService: LocationPermissionService(),
        searchDebouncer: Debouncer(delay: Duration.zero),
      ),
    );
  });

  tearDown(Get.reset);

  testWidgets('asks for three addresses and can add another stop', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: HomePage()));

    expect(find.text('Para onde vamos?'), findsOneWidget);
    expect(find.text('Ponto A'), findsOneWidget);
    expect(find.text('Ponto B'), findsOneWidget);
    expect(find.text('Ponto C'), findsOneWidget);
    expect(find.text('Preencha os 3 endereços para continuar'), findsOneWidget);
    expect(find.text('Adicionar ponto'), findsOneWidget);

    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirmar rota'),
    );
    expect(confirm.onPressed, isNull);

    await tester.tap(find.text('Adicionar ponto'));
    await tester.pump();

    expect(find.text('Ponto D'), findsOneWidget);
    expect(find.byTooltip('Remover ponto'), findsOneWidget);
  });
}
