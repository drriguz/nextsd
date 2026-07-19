# AGENTS.md

## Project

Next-Gen banking demo app (Flutter) using on-device LLM for private, intelligent banking assistance.

## Architecture

```
lib/
  main.dart                  → App entry, initializes FlutterGemma + LiteRtLmEngine; L10nProvider wraps MaterialApp
  models/
    chat_message.dart        → ChatMessage (text, isUser, timestamp)
    tranche.dart             → Tranche data model parsed from products.json
    transaction.dart         → Structured deposit Transaction model (SQLite)
    daily_transaction.dart   → DailyTransaction + MockTransactionGenerator (seeded weekly data)
  screens/
    home_screen.dart         → 5-tab shell: Home, My, Transfer, Wealth, Settings
    chat_screen.dart         → AI chat (structured deposits) with tool calls + streaming
    customer_service_screen.dart → 智能客服 chat
    tranche_detail_screen.dart   → Product detail page (pushed route)
    transfer_screen.dart         → Transfer form (own/others/international, prefills from smart search)
    change_password_screen.dart  → Change password page
    transaction_screen.dart      → SD transaction list (SQLite-backed)
    termsheet_screen.dart        → Mock PDF termsheet viewer
  services/
    model_service.dart            → Chat model lifecycle (install, load, chat, send)
    smart_search_service.dart     → Smart search: Qwen3 structured-output intent parsing
    financial_summary_service.dart→ Weekly financial summary generator (ChangeNotifier)
    product_service.dart          → Loads products.json from assets
    transaction_database.dart     → sqflite DB, seeds SD transactions on first run
    locale_provider.dart          → zh/en locale state
  widgets/
    message_bubble.dart      → Chat bubble widget
    tranche_card.dart        → Product/tranche summary card
    smart_search_delegate.dart   → LLM-powered global search (replaces text search)
assets/
  products.json              → Structured deposit tranche data
```

## Commands

```sh
flutter pub get          # install deps
flutter analyze          # lint/typecheck
flutter test             # run tests
flutter run -d macos     # run on macOS
flutter run -d android   # run on Android (requires device/emulator)
```

## Key Dependencies

- **flutter_gemma** ^1.3.0 — on-device LLM wrapper
- **flutter_gemma_litertlm** ^1.1.0 — LiteRT LM engine backend
- **path_provider** ^2.1.4 — app directory resolution
- **sqflite** ^2.4.2 — SQLite for SD transactions
- **path** ^1.9.1 — db path joining
- **intl** ^0.20.2 — formatting

## Model Setup (On-Device LLM)

The app uses **Qwen3-0.6B** (litertlm format, ~586MB) for all LLM features (chat, customer service, smart search, financial summary).

### Android
1. Manually place `Qwen3-0.6B.litertlm` at `/sdcard/Download/`
2. App copies it from Downloads → app documents dir on first launch

### macOS / iOS
- Model must exist at `~/Downloads/Qwen3-0.6B.litertlm`
- App reads it directly from there (no copy needed on desktop)

## LLM Feature Notes

- **Smart search** (`smart_search_service.dart`): uses **structured output**, NOT function calling. The model returns `{"action": ..., "params": {...}}` JSON; parsed locally. Uses non-streaming `generateChatResponse()` — the streaming API loses function-call responses due to a framework cancellation race on reused sessions.
- **Chat session reuse**: chat sessions are reused across queries (system prompt prefill ~10s happens once; reused prefill ~0.4s). On failure, session is recreated and retried once.
- **Financial summary** (`financial_summary_service.dart`): generates a weekly summary once at app start from `MockTransactionGenerator` seeded data (seed=42, stable per launch). ChangeNotifier; home page card rebuilds via AnimatedBuilder.
- **System prompts**: embedded as constants in each service file.

## Gotchas

- **macOS requires Apple Silicon**: `flutter_gemma_litertlm` only ships arm64 native libs. Intel Macs cannot run the LLM engine. The app still works for browsing products, but chat will show a platform error.
- **Default smoke test is stale**: `test/widget_test.dart` tests a counter app — it will fail. Replace it when writing real tests.
- **GPU backend**: model loading prefers GPU (`PreferredBackend.gpu`). On devices without GPU support, this may need changing to CPU.
- **Android storage permission**: requires "All files access" (MANAGE_EXTERNAL_STORAGE) on Android 11+. The native channel `com.nextsd.permission` handles this.
- **sqflite Transaction name clash**: `sqflite` exports its own `Transaction`; import as `import 'package:sqflite/sqflite.dart' hide Transaction;`.
- **Model incompatibility**: `mobile_actions_q8_ekv1024.litertlm` produces only `<pad>` tokens with every ModelType — do not use.
