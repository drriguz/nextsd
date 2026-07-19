import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/daily_transaction.dart';
import '../services/locale_provider.dart';
import '../services/smart_search_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final LocaleProvider localeProvider;

  const SplashScreen({super.key, required this.localeProvider});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = '';
  double _progress = 0.0;
  String? _error;

  AppStrings get l10n => AppStrings(widget.localeProvider);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _setStatus(String status, double progress) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _progress = progress;
    });
  }

  Future<void> _initialize() async {
    final l = l10n;
    _setStatus(l.splashInitializing, 0.1);

    // Prepare local mock data (synchronous, cheap)
    MockTransactionGenerator.instance.generate();
    await Future.delayed(const Duration(milliseconds: 300));

    _setStatus(l.splashLoadingModel, 0.4);

    try {
      await SmartSearchService.instance.initModel();

      _setStatus(l.splashModelReady, 1.0);
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) _goHome();
    } catch (e) {
      debugPrint('[SPLASH] Model init failed: $e');
      setState(() {
        _error = e.toString();
        _status = l.splashModelFailed;
        _progress = 0.4;
      });
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(localeProvider: widget.localeProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = l10n;
    final cs = Theme.of(context).colorScheme;
    final hasError = _error != null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      size: 72,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.appName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Progress
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: hasError ? null : _progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _progress = 0.0;
                            });
                            _initialize();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: Text(l.retry),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: _goHome,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: cs.primary,
                          ),
                          child: Text(l.continueAnyway),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
