import 'package:flutter_test/flutter_test.dart';
import 'package:developers/main.dart';
import 'package:developers/providers/scan_provider.dart';

void main() {
  testWidgets('Dashboard loads', (WidgetTester tester) async {
    final provider = ScanProvider();
    await tester.pumpWidget(VulnScannerApp(scanProvider: provider));
    expect(find.text('Security Dashboard'), findsOneWidget);
  });
}
