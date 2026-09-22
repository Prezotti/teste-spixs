import 'package:flutter_test/flutter_test.dart';
import 'package:teste_spixs/app.dart';

void main() {
  testWidgets('shows the auth lock screen', (tester) async {
    await tester.pumpWidget(const RotaApp());

    expect(find.text('Rota'), findsOneWidget);
    expect(find.textContaining('Entregas mais rápidas'), findsOneWidget);
    expect(find.text('Usar senha do celular'), findsOneWidget);
    expect(find.text('Use sua biometria\npara continuar'), findsNothing);
    expect(find.text('Ou use seu PIN'), findsNothing);
  });
}
