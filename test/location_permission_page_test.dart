import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/features/location/controllers/location_permission_controller.dart';
import 'package:teste_spixs/features/location/pages/location_permission_page.dart';

class _DeniedLocation extends LocationPermissionService {
  var requests = 0;

  @override
  Future<bool> request() async {
    requests++;
    return false;
  }
}

void main() {
  late _DeniedLocation location;

  setUp(() {
    location = _DeniedLocation();
    Get.put(
      LocationPermissionController(locationPermissionService: location),
    );
  });

  tearDown(Get.reset);

  testWidgets('offers location permission and stays when it is denied', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: LocationPermissionPage()));

    expect(find.text('Precisamos da sua localização'), findsOneWidget);
    expect(find.text('Permitir localização'), findsOneWidget);
    expect(find.text('Agora não'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Permitir localização'));
    await tester.pump();

    expect(location.requests, 1);
    expect(find.text('Precisamos da sua localização'), findsOneWidget);
    expect(find.byType(UIPrimaryButton), findsOneWidget);
  });
}
