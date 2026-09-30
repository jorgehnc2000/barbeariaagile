import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:barbearia_app/core/config/supabase_config.dart';
import 'package:barbearia_app/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  });

  testWidgets('Login screen renders when user is not authenticated', (
    tester,
  ) async {
    await tester.pumpWidget(const BarbeariaMouraApp(config: null));
    await tester.pump();

    expect(find.text('Barbearia'), findsOneWidget);
    expect(find.text('Continuar com o Google'), findsOneWidget);
  });
}
