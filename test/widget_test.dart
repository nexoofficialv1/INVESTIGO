import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/core/app_language.dart';
import 'package:investigo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_language_v1': 'bn',
    });
    await AppLanguageController.instance.load();
  });

  testWidgets('INVESTIGO application starts', (WidgetTester tester) async {
    await tester.pumpWidget(const InvestigationProcessApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(InvestigationProcessApp), findsOneWidget);
    expect(find.byType(StartupGate), findsOneWidget);
  });
}
