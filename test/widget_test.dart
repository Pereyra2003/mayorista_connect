import 'package:flutter_test/flutter_test.dart';
import 'package:mayorista_connect/main.dart';

void main() {
  testWidgets('MayoristaConnectApp renders properly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MayoristaConnectApp());

    // Verify that the dashboard screen is displayed.
    expect(find.text('Ruta Piura - Preventa App'), findsOneWidget);
  });
}
