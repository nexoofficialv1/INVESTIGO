import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/core/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('language preference survives a controller reload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_language_v1': 'en',
    });

    final controller = AppLanguageController.instance;
    await controller.load();
    expect(controller.current, AppLanguage.english);

    await controller.setLanguage(AppLanguage.bengali);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_language_v1'), 'bn');

    await controller.setLanguage(AppLanguage.english);
    expect(prefs.getString('app_language_v1'), 'en');

    // load() represents the persistence path used on app startup.
    await controller.load();
    expect(controller.current, AppLanguage.english);
  });
}
