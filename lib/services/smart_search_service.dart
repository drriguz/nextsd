import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

const _smartSearchModelFileName = 'Qwen3-0.6B.litertlm';
const _externalModelPath = '/sdcard/Download/$_smartSearchModelFileName';

const _smartSearchSystemPrompt = '''
You are a banking app intent parser. Analyze the user request and respond ONLY with a JSON object, no other text.

Available actions:
- change_password: user wants to change/reset password
- transfer_money: user wants to transfer money. params: amount (number), recipient (string)
- view_transactions: user wants to see transaction history
- view_products: user wants to browse wealth products
- contact_support: user wants customer service
- view_account: user wants to see account/balance info
- none: no matching action. params: reply (string, a short helpful answer)

Response format (JSON only, no markdown, no explanation):
{"action": "<action_name>", "params": {<params>}}

Examples:
User: 修改密码 → {"action": "change_password", "params": {}}
User: transfer 1000 to Zhang → {"action": "transfer_money", "params": {"amount": 1000, "recipient": "Zhang"}}
User: 转账给张三500元 → {"action": "transfer_money", "params": {"amount": 500, "recipient": "张三"}}
User: 我的余额 → {"action": "view_account", "params": {}}
User: 你好 → {"action": "none", "params": {"reply": "您好！请问有什么可以帮您？"}}
''';

class SmartSearchResult {
  final String? functionName;
  final Map<String, dynamic>? parameters;
  final String? textResponse;
  final bool isError;

  SmartSearchResult({
    this.functionName,
    this.parameters,
    this.textResponse,
    this.isError = false,
  });
}

class SmartSearchService {
  static final SmartSearchService instance = SmartSearchService._();

  dynamic _model;
  dynamic _chat;
  bool _isModelReady = false;
  bool _isLoading = false;
  String? _error;

  SmartSearchService._();

  bool get isModelReady => _isModelReady;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<String> _getModelPath() async {
    if (Platform.isAndroid) {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/$_smartSearchModelFileName';
    }
    return '${Platform.environment['HOME']}/Downloads/$_smartSearchModelFileName';
  }

  Future<void> initModel() async {
    if (_isModelReady || _isLoading) return;

    _isLoading = true;
    _error = null;

    try {
      final modelPath = await _getModelPath();
      debugPrint('[SMART_SEARCH] ==================== INIT START ====================');
      debugPrint('[SMART_SEARCH] Model path: $modelPath');

      if (Platform.isAndroid) {
        final destFile = File(modelPath);
        if (!await destFile.exists()) {
          final externalFile = File(_externalModelPath);
          if (await externalFile.exists()) {
            await externalFile.copy(modelPath);
          }
        }
      }

      final localFile = File(modelPath);
      if (!await localFile.exists()) {
        throw StateError('Model file not found at $modelPath. '
            'Please place $_smartSearchModelFileName in your Downloads folder.');
      }

      debugPrint('[SMART_SEARCH] Installing model with ModelType.qwen3...');
      await FlutterGemma.installModel(
        modelType: ModelType.qwen3,
        fileType: ModelFileType.litertlm,
      ).fromFile(modelPath).install();
      debugPrint('[SMART_SEARCH] Model installed successfully');

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: PreferredBackend.gpu,
      );
      debugPrint('[SMART_SEARCH] Model loaded: ${_model != null}');

      _isModelReady = true;
      _isLoading = false;
      debugPrint('[SMART_SEARCH] ==================== INIT SUCCESS ====================');
    } catch (e, stackTrace) {
      debugPrint('[SMART_SEARCH] ==================== INIT FAILED ====================');
      debugPrint('[SMART_SEARCH] Error: $e');
      debugPrint('[SMART_SEARCH] Stack trace: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      rethrow;
    }
  }

  Future<void> _createChat() async {
    debugPrint('[SMART_SEARCH] Creating chat (structured output, no function calls)...');
    if (_model == null) throw StateError('Model not loaded');

    _chat = await _model.createChat(
      systemInstruction: _smartSearchSystemPrompt,
      maxOutputTokens: 256,
      supportsFunctionCalls: false,
    );
    debugPrint('[SMART_SEARCH] Chat created: ${_chat != null}');
  }

  Future<SmartSearchResult> processQuery(String query) async {
    debugPrint('[SMART_SEARCH] ==================== PROCESS QUERY ====================');
    debugPrint('[SMART_SEARCH] Query: "$query"');

    if (!_isModelReady) {
      return SmartSearchResult(
        textResponse: 'Smart search model is not loaded yet.',
        isError: true,
      );
    }

    try {
      // Reuse existing chat (system prompt prefilled only once).
      if (_chat == null) await _createChat();
      return await _runQuery(query);
    } catch (e) {
      debugPrint('[SMART_SEARCH] Query failed on existing chat: $e');
      debugPrint('[SMART_SEARCH] Recreating chat and retrying once...');
      _chat = null;
      try {
        await _createChat();
        return await _runQuery(query);
      } catch (e2) {
        debugPrint('[SMART_SEARCH] Retry failed: $e2');
        return SmartSearchResult(
          textResponse: 'Error: $e2',
          isError: true,
        );
      }
    }
  }

  Future<SmartSearchResult> _runQuery(String query) async {
    debugPrint('[SMART_SEARCH] Adding query to chat...');
    await _chat!.addQuery(Message.text(text: query, isUser: true));

    debugPrint('[SMART_SEARCH] Generating response (non-streaming)...');
    final response = await _chat!.generateChatResponse().timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw StateError('Model response timed out');
      },
    );

    debugPrint('[SMART_SEARCH] Response type: ${response.runtimeType}');

    if (response is TextResponse) {
      final cleanText = response.token
          .replaceAll('<pad>', '')
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      debugPrint('[SMART_SEARCH] Text response: "$cleanText"');

      if (cleanText.isEmpty) {
        throw StateError('Empty response from model');
      }

      return _parseStructuredOutput(cleanText);
    }

    throw StateError('Unexpected response type: ${response.runtimeType}');
  }

  SmartSearchResult _parseStructuredOutput(String text) {
    try {
      // Extract JSON: from first { to last }
      final startIdx = text.indexOf('{');
      final endIdx = text.lastIndexOf('}');

      if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
        debugPrint('[SMART_SEARCH] No JSON found, returning as plain text');
        return SmartSearchResult(textResponse: text);
      }

      final jsonStr = text.substring(startIdx, endIdx + 1);
      debugPrint('[SMART_SEARCH] Extracted JSON: $jsonStr');

      final decoded = json.decode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return SmartSearchResult(textResponse: text);
      }

      final action = decoded['action'] as String?;
      final params = decoded['params'];

      debugPrint('[SMART_SEARCH] Parsed action: $action, params: $params');

      if (action == null || action == 'none') {
        // No action — return the reply text if present
        final reply = params is Map ? params['reply']?.toString() : null;
        return SmartSearchResult(textResponse: reply ?? text);
      }

      final validActions = [
        'change_password',
        'transfer_money',
        'view_transactions',
        'view_products',
        'contact_support',
        'view_account',
      ];

      if (validActions.contains(action)) {
        return SmartSearchResult(
          functionName: action,
          parameters: params is Map ? Map<String, dynamic>.from(params) : {},
        );
      }

      debugPrint('[SMART_SEARCH] Unknown action: $action');
      return SmartSearchResult(textResponse: text);
    } catch (e) {
      debugPrint('[SMART_SEARCH] Error parsing structured output: $e');
      return SmartSearchResult(textResponse: text);
    }
  }

  Future<void> resetChat() async {
    debugPrint('[SMART_SEARCH] Resetting chat...');
    _chat = null;
    if (_isModelReady) {
      await _createChat();
    }
  }

  Future<void> dispose() async {
    debugPrint('[SMART_SEARCH] Disposing...');
    _chat = null;
    await _model?.close();
    _model = null;
    _isModelReady = false;
  }
}
