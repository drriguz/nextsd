import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

const _modelUrl =
    'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm';

const _modelFileName = 'Qwen3-0.6B.litertlm';
const _externalModelPath = '/sdcard/Download/Qwen3-0.6B.litertlm';
String _getLocalModelPathDesktop() =>
    '${Platform.environment['HOME']}/Downloads/$_modelFileName';

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

  bool _isInstalling = false;
  bool _isModelReady = false;
  double _downloadProgress = 0.0;
  String _statusMessage = 'Model not loaded';

  dynamic get model => _model;
  bool get isInstalling => _isInstalling;
  bool get isModelReady => _isModelReady;
  double get downloadProgress => _downloadProgress;
  String get statusMessage => _statusMessage;

  Future<String> _getModelPath() async {
    if (Platform.isAndroid) {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/$_modelFileName';
    }
    return _getLocalModelPathDesktop();
  }

  Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final channel = MethodChannel('com.nextsd.permission');
      final granted = await channel.invokeMethod<bool>('checkStoragePermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openStorageSettings() async {
    if (Platform.isAndroid) {
      const channel = MethodChannel('com.nextsd.permission');
      await channel.invokeMethod('openAppSettings');
    }
  }

  Future<void> _copyFromExternalIfNeeded(String destPath, void Function(String)? onStatus) async {
    final externalFile = File(_externalModelPath);
    final destFile = File(destPath);

    if (await destFile.exists()) return;

    if (await externalFile.exists()) {
      onStatus?.call('Copying model to internal storage...');
      await externalFile.copy(destPath);
      onStatus?.call('Model copied successfully');
    }
  }

  Future<void> installModel({
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    if (_isInstalling) return;
    _isInstalling = true;

    try {
      final modelPath = await _getModelPath();

      if (Platform.isAndroid) {
        await _copyFromExternalIfNeeded(modelPath, onStatus);
      }

      final localFile = File(modelPath);

      if (await localFile.exists()) {
        onStatus?.call('Loading model from $modelPath...');
        _statusMessage = 'Loading local model...';
        await FlutterGemma.installModel(
          modelType: ModelType.qwen3,
          fileType: ModelFileType.litertlm,
        ).fromFile(modelPath).install();
      } else {
        onStatus?.call('Downloading Qwen3 0.6B model (586MB)...');
        _statusMessage = 'Downloading model...';
        await FlutterGemma.installModel(
          modelType: ModelType.qwen3,
          fileType: ModelFileType.litertlm,
        )
            .fromNetwork(_modelUrl)
            .withProgress((progress) {
              _downloadProgress = progress.toDouble();
              onProgress?.call(progress.toDouble());
            })
            .install();
      }

      _statusMessage = 'Model installed';
      onStatus?.call('Model installed successfully');
    } catch (e) {
      _statusMessage = 'Install failed: $e';
      onStatus?.call('Install failed: $e');
      rethrow;
    } finally {
      _isInstalling = false;
    }
  }

  Future<void> loadModel({
    void Function(String status)? onStatus,
  }) async {
    if (_isModelReady) return;

    try {
      onStatus?.call('Loading model into memory...');
      _statusMessage = 'Loading model...';

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
      );

      _statusMessage = 'Model loaded';
      _isModelReady = true;
      onStatus?.call('Model ready');
    } catch (e) {
      _statusMessage = 'Load failed: $e';
      onStatus?.call('Load failed: $e');
      rethrow;
    }
  }

  Future<void> createChat() async {
    if (_model == null) throw StateError('Model not loaded');
    _chat = await _model.createChat(
      systemInstruction: _systemPrompt,
      maxOutputTokens: 1024,
    );
  }

  Future<String> sendMessage(String userMessage) async {
    if (_chat == null) {
      await createChat();
    }

    await _chat.addQueryChunk(Message.text(
      text: userMessage,
      isUser: true,
    ));

    final response = await _chat.generateChatResponse();
    if (response is TextResponse) {
      return response.token;
    }
    return response.toString();
  }

  Stream<String> sendMessageStream(String userMessage) async* {
    if (_chat == null) {
      await createChat();
    }

    await _chat.addQueryChunk(Message.text(
      text: userMessage,
      isUser: true,
    ));

    await for (final response in _chat.generateChatResponseAsync()) {
      if (response is TextResponse) {
        yield response.token;
      }
    }
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
