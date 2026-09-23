import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/routes/app_routes.dart';
import 'package:teste_spixs/features/route/domain/entities/route_completion.dart';
import 'package:teste_spixs/features/route/pages/route_completed_page.dart';

void main() {
  testWidgets('shows the finished route and returns home', (tester) async {
    const summary = RouteCompletion(
      deliveries: 3,
      durationSeconds: 28 * 60,
      distanceMeters: 12400,
    );

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.home,
        getPages: [
          GetPage(
            name: AppRoutes.home,
            page: () => const Scaffold(body: Text('home')),
          ),
          GetPage(
            name: AppRoutes.routeCompleted,
            page: () => const RouteCompletedPage(summary: summary),
          ),
        ],
      ),
    );
    Get.toNamed(AppRoutes.routeCompleted);
    await tester.pumpAndSettle();

    expect(find.text('Rota concluída!'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('28 min'), findsOneWidget);
    expect(find.text('12,4 km'), findsOneWidget);
    expect(find.text('Concluir'), findsOneWidget);
    expect(find.text('Ver resumo'), findsNothing);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
