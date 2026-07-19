import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

const _modelFileName = 'Qwen3-0.6B.litertlm';
const _externalModelPath = '/sdcard/Download/Qwen3-0.6B.litertlm';

const _systemPrompt = '''
You are a helpful banking assistant specializing in Structured Deposits for an internal bank demo.

A Structured Deposit is a bank deposit where the return is linked to the performance of an underlying asset (e.g., equity index, interest rate, FX rate, or a basket of assets). Unlike conventional fixed deposits, the coupon or principal repayment may vary depending on market conditions.

Key topics you can help with:
- Product explanation: what Structured Deposits are, how they differ from plain deposits and investments
- Risk/return profile: capital protection levels, conditional coupons, worst-case scenarios
- Tenor and maturity: typical investment horizons (e.g., 1 month to 5 years)
- Underlying assets: equity indices, single stocks, interest rates, FX, commodities
- Barrier and strike levels: knock-in/knock-out conditions, autocall features
- Coupon structures: fixed, conditional, range accrual, phoenix coupons
- Early termination: autocall triggers, investor callability
- KYC/compliance: suitability assessment, risk disclosures, regulatory notes

Guidelines:
- Be professional and concise.
- Always remind users that this is for demo purposes and actual product terms may vary.
- Do NOT provide personalized investment advice. Always recommend consulting a relationship manager.
- Use simple language; avoid excessive jargon unless the user is clearly knowledgeable.
- If asked about topics outside Structured Deposits, politely redirect to the relevant department.
''';

class ModelService {
  dynamic _model;
  dynamic _chat;
  String _locale = 'zh';
  List<Tool> _tools = const [];

  bool _isModelReady = false;
  String _statusMessage = 'Model not loaded';

  bool get isModelReady => _isModelReady;
  String get statusMessage => _statusMessage;

  Future<String> _getModelPath() async {
    if (Platform.isAndroid) {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/$_modelFileName';
    }
    return '${Platform.environment['HOME']}/Downloads/$_modelFileName';
  }

  Future<void> _copyFromExternalIfNeeded(String destPath) async {
    if (!Platform.isAndroid) return;

    final destFile = File(destPath);
    if (await destFile.exists()) return;

    final externalFile = File(_externalModelPath);
    if (await externalFile.exists()) {
      await externalFile.copy(destPath);
    }
  }

  Future<void> initAndLoad(String modelName, {String locale = 'zh', List<Tool> tools = const []}) async {
    _locale = locale;
    _tools = tools;

    if (_isModelReady) return;

    try {
      final modelPath = await _getModelPath();

      await _copyFromExternalIfNeeded(modelPath);

      final localFile = File(modelPath);
      if (!await localFile.exists()) {
        throw StateError('Model file not found at $modelPath. '
            'Please place $_modelFileName in your Downloads folder.');
      }

      _statusMessage = 'Installing model...';
      await FlutterGemma.installModel(
        modelType: ModelType.qwen3,
        fileType: ModelFileType.litertlm,
      ).fromFile(modelPath).install();

      _statusMessage = 'Loading model...';
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
      );

      _isModelReady = true;
      _statusMessage = 'Model ready';
    } catch (e) {
      _statusMessage = 'Load failed: $e';
      rethrow;
    }
  }

  String get _fullSystemPrompt {
    if (_locale == 'zh') {
      return '$_systemPrompt\n\nIMPORTANT: Always respond in Chinese (中文).';
    }
    return '$_systemPrompt\n\nIMPORTANT: Always respond in English.';
  }

  Future<void> createChat() async {
    if (_model == null) throw StateError('Model not loaded');
    _chat = await _model.createChat(
      systemInstruction: _fullSystemPrompt,
      maxOutputTokens: 1024,
      supportsFunctionCalls: _tools.isNotEmpty,
      tools: _tools,
    );
  }

  Stream<ModelResponse> sendMessageStream(String userMessage) async* {
    if (_chat == null) {
      await createChat();
    }

    await _chat!.addQuery(Message.text(
      text: userMessage,
      isUser: true,
    ));

    await for (final response in _chat!.generateChatResponseAsync()) {
      yield response;
    }
  }

  Future<ModelResponse> sendToolResponse(String toolName, Map<String, dynamic> result) async {
    debugPrint('[MODEL] sendToolResponse: $toolName');
    await _chat!.addQuery(Message.toolResponse(
      toolName: toolName,
      response: result,
    ));
    debugPrint('[MODEL] tool response sent, waiting for model...');
    final response = await _chat!.generateChatResponse();
    debugPrint('[MODEL] generateChatResponse returned: ${response.runtimeType}');
    return response;
  }

  Future<Map<String, dynamic>?> runStructuredQuery(
      String systemInstruction, String userMessage) async {
    if (_model == null) throw StateError('Model not loaded');

    final tempChat = await _model.createChat(
      systemInstruction: systemInstruction,
      maxOutputTokens: 512,
      supportsFunctionCalls: false,
    );

    await tempChat.addQuery(Message.text(text: userMessage, isUser: true));
    final response = await tempChat.generateChatResponse();

    if (response is TextResponse) {
      final clean = response.token.replaceAll('<pad>', '').trim();
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        try {
          final decoded = json.decode(clean.substring(start, end + 1));
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {}
      }
      return {'reply': clean};
    }
    return null;
  }

  Future<void> resetChat() async {
    _chat = null;
    await createChat();
  }

  Future<void> dispose() async {
    _chat = null;
    await _model?.close();
    _model = null;
    _isModelReady = false;
  }
}
