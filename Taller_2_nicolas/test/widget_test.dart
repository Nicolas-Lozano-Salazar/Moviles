import 'package:flutter_test/flutter_test.dart';
import 'package:taller_segundo_plano/main.dart';

void main() {
  testWidgets('Smoke test de la aplicación TallerSegundoPlanoApp', (WidgetTester tester) async {
    // Construir la aplicación
    await tester.pumpWidget(const TallerSegundoPlanoApp());

    // Verificar que el título principal y las tabs se renderizan
    expect(find.textContaining('Future'), findsWidgets);
    expect(find.textContaining('Timer'), findsWidgets);
    expect(find.textContaining('Isolate'), findsWidgets);
  });
}
