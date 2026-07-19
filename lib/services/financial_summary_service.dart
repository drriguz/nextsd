import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import '../models/daily_transaction.dart';

const _modelFileName = 'Qwen3-0.6B.litertlm';
const _externalModelPath = '/sdcard/Download/$_modelFileName';

const _systemPromptZh = '''
你是一位专业的银行财务顾问。根据用户提供的本周财务数据，生成一段简短的财务周报摘要。

要求：
- 使用第二人称"您"，语气友好专业
- 100字以内
- 指出总收入、总支出和净流入
- 指出最主要的1-2个支出类别
- 给出一条实用的财务建议
- 直接输出摘要正文，不要标题、不要markdown格式
''';

const _systemPromptEn = '''
You are a professional banking financial advisor. Generate a short weekly financial summary based on the user's data.

Requirements:
- Use second person "you", friendly and professional tone
- Under 60 words
- Mention total income, total expenses, and net cash flow
- Point out the top 1-2 expense categories
- Give one practical financial tip
- Output the summary directly, no title, no markdown
''';

class FinancialSummaryService extends ChangeNotifier {
  static final FinancialSummaryService instance = FinancialSummaryService._();

  dynamic _model;
  dynamic _chat;
  bool _isModelReady = false;
  bool _isGenerating = false;
  bool _generated = false;
  String? _summary;
  String? _error;

  FinancialSummaryService._();

  bool get isGenerating => _isGenerating;
  bool get generated => _generated;
  String? get summary => _summary;
  String? get error => _error;

  Future<String> _getModelPath() async {
    if (Platform.isAndroid) {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/$_modelFileName';
    }
    return '${Platform.environment['HOME']}/Downloads/$_modelFileName';
  }

  Future<void> initAndGenerate({required bool isZh}) async {
    if (_generated || _isGenerating) return;

    try {
      await _initModel();
      await _generateSummary(isZh: isZh);
    } catch (e) {
      debugPrint('[FIN_SUMMARY] Failed: $e');
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> _initModel() async {
    if (_isModelReady) return;

    final modelPath = await _getModelPath();
    debugPrint('[FIN_SUMMARY] Model path: $modelPath');

    if (Platform.isAndroid) {
      final destFile = File(modelPath);
      if (!await destFile.exists()) {
        final externalFile = File(_externalModelPath);
        if (await externalFile.exists()) {
          await externalFile.copy(modelPath);
        }
      }
    }

    if (!await File(modelPath).exists()) {
      throw StateError('Model file not found at $modelPath');
    }

    // Model is already installed by SmartSearchService via splash screen.
    // Avoid re-installing (would invalidate SmartSearchService's reference).
    _model = await FlutterGemma.getActiveModel(
      maxTokens: 2048,
      preferredBackend: PreferredBackend.gpu,
    );

    _isModelReady = true;
    debugPrint('[FIN_SUMMARY] Model ready');
  }

  Future<void> _generateSummary({required bool isZh}) async {
    if (_isGenerating) return;
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final data = MockTransactionGenerator.instance.weeklySummary;
      final prompt = _buildDataPrompt(data, isZh);
      debugPrint('[FIN_SUMMARY] Prompt:\n$prompt');

      _chat = await _model.createChat(
        systemInstruction: isZh ? _systemPromptZh : _systemPromptEn,
        maxOutputTokens: 256,
        supportsFunctionCalls: false,
      );

      await _chat.addQuery(Message.text(text: prompt, isUser: true));

      final response = await _chat.generateChatResponse().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw StateError('Summary generation timed out'),
      );

      if (response is TextResponse) {
        _summary = response.token.replaceAll('<pad>', '').trim();
        debugPrint('[FIN_SUMMARY] Generated summary: $_summary');
      } else {
        throw StateError('Unexpected response: ${response.runtimeType}');
      }

      _generated = true;
    } catch (e) {
      debugPrint('[FIN_SUMMARY] Generation error: $e');
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  String _buildDataPrompt(WeeklySummary data, bool isZh) {
    final buffer = StringBuffer();

    if (isZh) {
      buffer.writeln('本周财务数据：');
      buffer.writeln('总收入：¥${data.totalIncome.toStringAsFixed(2)}');
      buffer.writeln('总支出：¥${data.totalExpense.toStringAsFixed(2)}');
      buffer.writeln('净流入：¥${data.netCashFlow.toStringAsFixed(2)}');
      buffer.writeln();
      buffer.writeln('支出分类明细：');
      final sorted = data.expenseByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted) {
        buffer.writeln('- ${e.key.label(true)}：¥${e.value.toStringAsFixed(2)}');
      }
      buffer.writeln();
      buffer.writeln('收入分类明细：');
      for (final e in data.incomeByCategory.entries) {
        buffer.writeln('- ${e.key.label(true)}：¥${e.value.toStringAsFixed(2)}');
      }
    } else {
      buffer.writeln('Weekly financial data:');
      buffer.writeln('Total income: ¥${data.totalIncome.toStringAsFixed(2)}');
      buffer.writeln('Total expenses: ¥${data.totalExpense.toStringAsFixed(2)}');
      buffer.writeln('Net cash flow: ¥${data.netCashFlow.toStringAsFixed(2)}');
      buffer.writeln();
      buffer.writeln('Expense breakdown:');
      final sorted = data.expenseByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted) {
        buffer.writeln('- ${e.key.label(false)}: ¥${e.value.toStringAsFixed(2)}');
      }
      buffer.writeln();
      buffer.writeln('Income breakdown:');
      for (final e in data.incomeByCategory.entries) {
        buffer.writeln('- ${e.key.label(false)}: ¥${e.value.toStringAsFixed(2)}');
      }
    }

    return buffer.toString();
  }

  Future<void> regenerate({required bool isZh}) async {
    _generated = false;
    _summary = null;
    _chat = null;
    notifyListeners();
    await _generateSummary(isZh: isZh);
  }

  Future<void> shutdown() async {
    _chat = null;
    await _model?.close();
    _model = null;
    _isModelReady = false;
  }
}
