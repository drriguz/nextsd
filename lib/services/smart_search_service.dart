import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

const _smartSearchModelFileName = 'Qwen3-0.6B.litertlm';
const _externalModelPath = '/sdcard/Download/$_smartSearchModelFileName';

const _smartSearchSystemPrompt = '''
You are a smart banking assistant. When users want to perform actions, call the appropriate function.

Available functions:
- change_password: when user wants to change or reset password
- transfer_money: when user wants to make a transfer (extract amount and recipient if mentioned)
- view_transactions: when user wants to see transaction history
- view_products: when user wants to browse products
- contact_support: when user wants to talk to customer service
- view_account: when user wants to see account info

Always use function calls for actions. Extract parameters from user input.
''';

List<Tool> get _smartSearchTools => [
  Tool(
    name: 'change_password',
    description: 'Navigate to change password page',
  ),
  Tool(
    name: 'transfer_money',
    description: 'Navigate to transfer page with optional amount and recipient',
    parameters: {
      'type': 'object',
      'properties': {
        'amount': {
          'type': 'number',
          'description': 'Transfer amount if mentioned',
        },
        'recipient': {
          'type': 'string',
          'description': 'Recipient name if mentioned',
        },
      },
    },
  ),
  Tool(
    name: 'view_transactions',
    description: 'Show transaction history',
  ),
  Tool(
    name: 'view_products',
    description: 'Show available products',
  ),
  Tool(
    name: 'contact_support',
    description: 'Open customer service',
  ),
  Tool(
    name: 'view_account',
    description: 'View account details',
  ),
];

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
      debugPrint('[SMART_SEARCH] Platform: ${Platform.operatingSystem}');

      // Check external path on Android
      if (Platform.isAndroid) {
        final externalFile = File(_externalModelPath);
        final externalExists = await externalFile.exists();
        debugPrint('[SMART_SEARCH] External path: $_externalModelPath');
        debugPrint('[SMART_SEARCH] External file exists: $externalExists');
        if (externalExists) {
          final externalSize = await externalFile.length();
          debugPrint('[SMART_SEARCH] External file size: ${(externalSize / 1024 / 1024).toStringAsFixed(2)} MB');
        }

        final destFile = File(modelPath);
        if (!await destFile.exists()) {
          if (externalExists) {
            debugPrint('[SMART_SEARCH] Copying from external to app directory...');
            await externalFile.copy(modelPath);
            debugPrint('[SMART_SEARCH] Copy complete');
          }
        }
      }

      final localFile = File(modelPath);
      final fileExists = await localFile.exists();
      debugPrint('[SMART_SEARCH] Local file exists: $fileExists');

      if (!fileExists) {
        throw StateError('Model file not found at $modelPath. '
            'Please place $_smartSearchModelFileName in your Downloads folder.');
      }

      final fileSize = await localFile.length();
      debugPrint('[SMART_SEARCH] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      debugPrint('[SMART_SEARCH] Installing model with ModelType.qwen3...');
      await FlutterGemma.installModel(
        modelType: ModelType.qwen3,
        fileType: ModelFileType.litertlm,
      ).fromFile(modelPath).install();
      debugPrint('[SMART_SEARCH] Model installed successfully');

      debugPrint('[SMART_SEARCH] Getting active model...');
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
    debugPrint('[SMART_SEARCH] Creating chat with function calling support...');
    if (_model == null) throw StateError('Model not loaded');
    
    try {
      _chat = await _model.createChat(
        systemInstruction: _smartSearchSystemPrompt,
        maxOutputTokens: 512,
        supportsFunctionCalls: true,
        tools: _smartSearchTools,
      );
      debugPrint('[SMART_SEARCH] Chat created successfully: ${_chat != null}');
    } catch (e) {
      debugPrint('[SMART_SEARCH] Chat creation with function calls failed: $e');
      debugPrint('[SMART_SEARCH] Trying without function calls...');
      
      // Fallback: try without function calling
      _chat = await _model.createChat(
        systemInstruction: _smartSearchSystemPrompt,
        maxOutputTokens: 512,
        supportsFunctionCalls: false,
      );
      debugPrint('[SMART_SEARCH] Chat created without function calls: ${_chat != null}');
    }
  }

  Future<SmartSearchResult> processQuery(String query) async {
    debugPrint('[SMART_SEARCH] ==================== PROCESS QUERY ====================');
    debugPrint('[SMART_SEARCH] Query: "$query"');
    debugPrint('[SMART_SEARCH] Model ready: $_isModelReady');

    if (!_isModelReady) {
      debugPrint('[SMART_SEARCH] Model not ready, returning error');
      return SmartSearchResult(
        textResponse: 'Smart search model is not loaded yet.',
        isError: true,
      );
    }

    try {
      // Always create a fresh chat for each query
      debugPrint('[SMART_SEARCH] Creating fresh chat...');
      await _createChat();

      debugPrint('[SMART_SEARCH] Adding query to chat...');
      await _chat!.addQuery(Message.text(
        text: query,
        isUser: true,
      ));
      debugPrint('[SMART_SEARCH] Query added, generating response...');

      int responseCount = 0;
      String allTextTokens = '';
      bool hasResponse = false;

      // Add timeout to prevent infinite waiting
      await for (final response in _chat!.generateChatResponseAsync().timeout(
        const Duration(seconds: 30),
        onTimeout: (sink) {
          debugPrint('[SMART_SEARCH] Stream timeout after 30 seconds');
          sink.close();
        },
      )) {
        responseCount++;
        debugPrint('[SMART_SEARCH] Response #$responseCount type: ${response.runtimeType}');

        if (response is FunctionCallResponse) {
          debugPrint('[SMART_SEARCH] >>> FUNCTION CALL DETECTED');
          debugPrint('[SMART_SEARCH] Function: ${response.name}');
          debugPrint('[SMART_SEARCH] Args: ${response.args}');
          hasResponse = true;
          return SmartSearchResult(
            functionName: response.name,
            parameters: response.args,
          );
        }
        
        if (response is ParallelFunctionCallResponse) {
          debugPrint('[SMART_SEARCH] >>> PARALLEL FUNCTION CALL DETECTED');
          debugPrint('[SMART_SEARCH] Calls count: ${response.calls.length}');
          if (response.calls.isNotEmpty) {
            final call = response.calls.first;
            debugPrint('[SMART_SEARCH] First function: ${call.name}');
            debugPrint('[SMART_SEARCH] First args: ${call.args}');
            hasResponse = true;
            return SmartSearchResult(
              functionName: call.name,
              parameters: call.args,
            );
          }
        }

        if (response is TextResponse) {
          final token = response.token;
          debugPrint('[SMART_SEARCH] Text token: "$token" (length: ${token.length})');
          allTextTokens += token;
          hasResponse = true;
          
          // Stop early if we detect padding tokens
          if (responseCount > 5 && allTextTokens.contains('<pad>') && !allTextTokens.contains(RegExp(r'[a-zA-Z\u4e00-\u9fff]'))) {
            debugPrint('[SMART_SEARCH] Detected only pad tokens, stopping early');
            break;
          }
        }
      }

      debugPrint('[SMART_SEARCH] Total responses: $responseCount');
      debugPrint('[SMART_SEARCH] Has response: $hasResponse');
      debugPrint('[SMART_SEARCH] All text tokens length: ${allTextTokens.length}');

      if (!hasResponse) {
        debugPrint('[SMART_SEARCH] No response received from model');
        return SmartSearchResult(
          textResponse: 'No response received. Please try again.',
          isError: true,
        );
      }

      // Clean up pad tokens
      final cleanText = allTextTokens.replaceAll('<pad>', '').trim();
      
      if (cleanText.isEmpty) {
        debugPrint('[SMART_SEARCH] No meaningful text generated (only pad tokens)');
        return SmartSearchResult(
          textResponse: 'Model did not generate a valid response. The model file may be incompatible.',
          isError: true,
        );
      }

      debugPrint('[SMART_SEARCH] Clean text: "$cleanText"');
      
      // Try to parse as JSON function call
      final functionCall = _parseFunctionCall(cleanText);
      if (functionCall != null) {
        debugPrint('[SMART_SEARCH] Parsed function call from text: ${functionCall.functionName}');
        return functionCall;
      }

      return SmartSearchResult(textResponse: cleanText);
    } catch (e, stackTrace) {
      debugPrint('[SMART_SEARCH] Error processing query: $e');
      debugPrint('[SMART_SEARCH] Stack trace: $stackTrace');
      return SmartSearchResult(
        textResponse: 'Error: $e',
        isError: true,
      );
    }
  }

  SmartSearchResult? _parseFunctionCall(String text) {
    try {
      // Try to parse the entire text as JSON
      debugPrint('[SMART_SEARCH] Trying to parse text as JSON: $text');
      
      // Find the first { and last } to extract JSON
      final startIdx = text.indexOf('{');
      final endIdx = text.lastIndexOf('}');
      
      if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
        debugPrint('[SMART_SEARCH] No JSON found in text');
        return null;
      }

      final jsonStr = text.substring(startIdx, endIdx + 1);
      debugPrint('[SMART_SEARCH] Extracted JSON: $jsonStr');

      // Try direct JSON parse
      final Map<String, dynamic>? parsed = _tryParseJson(jsonStr);
      if (parsed == null) {
        debugPrint('[SMART_SEARCH] Failed to parse JSON');
        return null;
      }
      
      debugPrint('[SMART_SEARCH] Parsed JSON keys: ${parsed.keys.toList()}');

      // Check if it's a function call format: {"function_name": {params}}
      for (final entry in parsed.entries) {
        final functionName = entry.key;
        final validFunctions = [
          'change_password',
          'transfer_money',
          'view_transactions',
          'view_products',
          'contact_support',
          'view_account',
        ];

        debugPrint('[SMART_SEARCH] Checking key: $functionName, is valid: ${validFunctions.contains(functionName)}');

        if (validFunctions.contains(functionName)) {
          Map<String, dynamic> params = {};
          if (entry.value is Map) {
            params = Map<String, dynamic>.from(entry.value as Map);
          }
          debugPrint('[SMART_SEARCH] Found function call: $functionName with params: $params');
          return SmartSearchResult(
            functionName: functionName,
            parameters: params,
          );
        }
      }

      // Check if the JSON itself is the function call format: {"name": "func", "args": {...}}
      if (parsed.containsKey('name') && parsed.containsKey('args')) {
        final functionName = parsed['name'] as String?;
        final args = parsed['args'];
        if (functionName != null && args is Map) {
          debugPrint('[SMART_SEARCH] Found function call (name/args format): $functionName');
          return SmartSearchResult(
            functionName: functionName,
            parameters: Map<String, dynamic>.from(args),
          );
        }
      }

      debugPrint('[SMART_SEARCH] No valid function call found in JSON');
      return null;
    } catch (e) {
      debugPrint('[SMART_SEARCH] Error parsing function call: $e');
      return null;
    }
  }

  Map<String, dynamic>? _tryParseJson(String str) {
    try {
      final decoded = json.decode(str);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      return null;
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
