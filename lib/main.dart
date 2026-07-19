import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'l10n/app_strings.dart';
import 'screens/splash_screen.dart';
import 'services/locale_provider.dart';

bool gemmaSupported = true;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine()],
      maxDownloadRetries: 10,
    ).catchError((e) {
      debugPrint('FlutterGemma init failed: $e');
      gemmaSupported = false;
    });
  } catch (_) {
    gemmaSupported = false;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _AppShell();
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  final _localeProvider = LocaleProvider();

  @override
  void dispose() {
    _localeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return L10nProvider(
      localeProvider: _localeProvider,
      child: MaterialApp(
        title: 'Structured Deposit Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: SplashScreen(localeProvider: _localeProvider),
      ),
    );
  }
}
