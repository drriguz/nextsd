# NextSD — On-Device AI Banking App

A Flutter banking demo app using **on-device LLM** (Qwen3-0.6B) for private, intelligent features — all analysis runs locally, no data leaves the device.

## AI Features

| Feature | Description | Model |
|---|---|---|
| **Smart Search** | Natural language → action. E.g. "修改密码" opens Change Password, "transfer 1000 to Zhang" opens Transfer with pre-filled fields, "上个月的收入" shows filtered transactions | Qwen3-0.6B |
| **Financial Summary** | AI-generated weekly financial report with income, expenses, top categories, and personalized advice. Displayed on Home page. | Qwen3-0.6B |
| **Smart Customer Service** | Intent detection (complaint/inquiry/suggestion), emotion analysis (frustrated/angry/positive), on-device triage with PII-stripped ticket summary ready for backend dispatch | Qwen3-0.6B |
| **Product AI Advisor** | Per-product chat on tranche detail pages. Tap "AI Advisor" FAB to ask questions about a specific structured deposit (risk, protection, suitability) | Gemma-4-E2B-it |
| **Structured Deposit Chat** | Full AI assistant for structured deposit Q&A with tool calling (list products, get details, open term sheet) | Qwen3-0.6B |

## Model Setup

Download the required model files and place them in your Downloads folder:

| Model | File | Used For | Size |
|---|---|---|---|
| Qwen3-0.6B | `Qwen3-0.6B.litertlm` | Smart search, financial summary, customer service, SD chat | ~586MB |
| Gemma-4-E2B-it | `gemma-4-E2B-it.litertlm` | Product AI advisor (per-product chat) | ~1.5GB |

**Android:** Place files in `/sdcard/Download/` — the app copies them to its documents directory on first launch.

**macOS:** Place files in `~/Downloads/` — the app reads them directly.

Both models use the **LiteRT LM** engine with GPU acceleration (requires arm64 Apple Silicon on macOS, or a GPU-enabled Android device).

## How to Run

```sh
# Install dependencies
flutter pub get

# Check for issues
flutter analyze

# Run on macOS (requires Apple Silicon)
flutter run -d macos

# Run on Android (requires device/emulator with GPU)
flutter run -d android
```

**Requirements:**
- Flutter SDK `^3.12.2`
- macOS: Apple Silicon (arm64) — Intel Macs cannot run the LLM engine
- Android: GPU support + "All files access" permission on Android 11+

## Architecture

```
lib/
  main.dart                    → App entry, splash screen, L10nProvider
  models/
    chat_message.dart          → ChatMessage
    tranche.dart               → Structured deposit product model
    transaction.dart           → SD transaction (SQLite)
    daily_transaction.dart     → Mock daily banking transactions
  screens/
    splash_screen.dart         → Model init splash with progress
    home_screen.dart           → 5-tab shell (Home, My, Transfer, Wealth, Settings)
    chat_screen.dart           → Structured deposit AI chat
    customer_service_screen.dart → 智能客服 with on-device triage
    product_chat_screen.dart   → Per-product AI advisor (Gemma-4)
    tranche_detail_screen.dart → Product detail + AI advisor FAB
    transfer_screen.dart       → Transfer form
    change_password_screen.dart
    daily_transaction_screen.dart → Transaction history with filters
    transaction_screen.dart    → SD transactions (SQLite)
    termsheet_screen.dart      → Mock PDF viewer
  services/
    model_service.dart         → Qwen3 chat model lifecycle
    smart_search_service.dart  → Structured-output intent parsing
    financial_summary_service.dart → AI weekly summary (ChangeNotifier)
    product_service.dart       → Loads products.json
    transaction_database.dart  → sqflite DB for SD transactions
    locale_provider.dart       → zh/en locale
  widgets/
    message_bubble.dart        → Chat bubble
    tranche_card.dart          → Product card
    smart_search_delegate.dart → Smart search UI + action execution
    global_search_delegate.dart → Legacy text search
```

## Tabs

| Tab | Content |
|---|---|
| **Home** | Welcome hero, asset summary, 6-item feature grid, financial summary card, recent transactions |
| **My** | Profile, account cards (savings/deposits/investments), quick services |
| **Transfer** | Own/other/international transfer types, transfer history |
| **Wealth** | Investment summary, weekly income/expense breakdown, recent transactions → View All, structured deposit product list with filters |
| **Settings** | Account info, language switcher, change password, notifications, help, model selection |

## Gotchas

- **macOS requires Apple Silicon**: `flutter_gemma_litertlm` only ships arm64 native libs
- **Android storage**: requires "All files access" on Android 11+
- **sqflite name clash**: sqflite exports `Transaction`; use `hide Transaction` when importing
- **Chat session reuse**: Prefill of system prompt costs ~10s for new sessions; reused sessions prefill in ~0.4s
- **Streaming vs non-streaming**: Smart search uses non-streaming `generateChatResponse()` to avoid a framework cancellation race that drops function-call responses on reused streaming sessions
- **mobile_actions model**: `mobile_actions_q8_ekv1024.litertlm` produces only `<pad>` tokens — do not use
