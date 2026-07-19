# AGENTS.md

## Project

Next-Gen Structured Deposit demo app (Flutter) using on-device LLM for private, intelligent banking assistance.

## Architecture

```
lib/
  main.dart                  → App entry, initializes FlutterGemma + LiteRtLmEngine
  models/
    chat_message.dart        → ChatMessage (text, isUser, timestamp)
    tranche.dart             → Tranche data model parsed from products.json
  screens/
    home_screen.dart         → Tab-based shell: Home (tranche list) + Settings, with chat FAB
    chat_screen.dart         → Chat UI with model install/load flow + streaming
  services/
    model_service.dart       → Model lifecycle: install, load, chat, send
    product_service.dart     → Loads products.json from assets
  widgets/
    message_bubble.dart      → Chat bubble widget
    tranche_card.dart        → Product/trance summary card
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

## Model Setup (On-Device LLM)

The app uses **Qwen3-0.6B** (litertlm format, ~586MB).

### Android
1. Manually place `Qwen3-0.6B.litertlm` at `/sdcard/Download/`
2. App copies it from Downloads → app documents dir on first launch
3. Falls back to network download if file not found

### macOS / iOS
- Model must exist at `~/Downloads/Qwen3-0.6B.litertlm`
- App reads it directly from there (no copy needed on desktop)

### Model Install Flow
`main()` calls `FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()])` before `runApp()`. The chat screen then:
1. Tries loading model from disk (if installed)
2. If no model found, prompts user to tap download button
3. On Android: requests storage permission via `MethodChannel('com.nextsd.permission')`
4. Installs via `FlutterGemma.installModel(...).fromFile(path)` or `.fromNetwork(url)`
5. Loads with `FlutterGemma.getActiveModel(maxTokens: 4096, preferredBackend: PreferredBackend.gpu)`

## Gotchas

- **Default smoke test is stale**: `test/widget_test.dart` tests a counter app — it will fail. Replace it when writing real tests.
- **GPU backend**: model loading prefers GPU (`PreferredBackend.gpu`). On devices without GPU support, this may need changing to CPU.
- **Android storage permission**: requires "All files access" (MANAGE_EXTERNAL_STORAGE) on Android 11+. The native channel `com.nextsd.permission` handles this.
- **Streaming and non-streaming**: `sendMessageStream()` for real-time UI; `sendMessage()` for blocking calls.
- **Chat reset**: `resetChat()` creates a new chat session with the system prompt — history is lost.
- **System prompt**: embedded in `_systemPrompt` constant in `model_service.dart` — defines the banking assistant persona and structured deposits knowledge boundaries.
