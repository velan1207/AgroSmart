// Basic widget test for AgroSmart app
import 'package:flutter_test/flutter_test.dart';
import 'package:crop_monitor/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CropMonitorApp());
    
    // Verify that the app loads
    expect(find.text('AgroSmart'), findsAny);
  });
}
