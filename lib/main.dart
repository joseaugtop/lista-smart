import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/persistence/shared_preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent FOIT: disable runtime font fetching before any widget renders.
  // Bundled Inter .ttf assets are used instead of CDN download.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize pt_BR locale data before any DateFormat/NumberFormat usage.
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';

  // Await SharedPreferences before runApp so all providers receive it synchronously.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the real instance — providers that depend on sharedPreferencesProvider
        // receive this value synchronously, with no async gap inside providers.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}
