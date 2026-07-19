import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/chat_message.dart';
import '../models/daily_transaction.dart';
import '../services/model_service.dart';
import '../widgets/message_bubble.dart';

class CSTriageResult {
  final String intent;
  final String emotion;
  final String summary;
  final String reply;

  CSTriageResult({
    required this.intent,
    required this.emotion,
    required this.summary,
    required this.reply,
  });

  factory CSTriageResult.fromJson(Map<String, dynamic> json) {
    return CSTriageResult(
      intent: json['intent']?.toString() ?? 'unknown',
      emotion: json['emotion']?.toString() ?? 'neutral',
      summary: json['summary']?.toString() ?? '',
      reply: json['reply']?.toString() ?? '',
    );
  }
}

class CustomerServiceScreen extends StatefulWidget {
  final String locale;

  const CustomerServiceScreen({super.key, required this.locale});

  @override
  State<CustomerServiceScreen> createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends State<CustomerServiceScreen> {
  final ModelService _modelService = ModelService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = true;
  bool _isGenerating = false;
  bool _triaged = false;
  CSTriageResult? _triageResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    if (!gemmaSupported) {
      setState(() {
        _isLoading = false;
        _error = 'On-device LLM is not supported on this platform.';
      });
      return;
    }

    try {
      await _modelService.initAndLoad('Qwen3-0.6B', locale: widget.locale);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _buildTriagePrompt() {
    final isZh = widget.locale == 'zh';
    final summary = MockTransactionGenerator.instance.weeklySummary;
    final topExpenses = summary.topExpenseCategories;

    final contextLines = isZh
        ? [
            '账户余额：CNY 2,350,000',
            '活跃结构性存款：3笔（总计 CNY 5,000,000）',
            '本周净流入：¥${summary.netCashFlow.toStringAsFixed(0)}',
            '本周主要支出：${topExpenses.map((e) => '${e.key.label(true)} ¥${e.value.toStringAsFixed(0)}').join('、')}',
          ]
        : [
            'Balance: CNY 2,350,000',
            'Active deposits: 3 (total CNY 5,000,000)',
            'Weekly net flow: ¥${summary.netCashFlow.toStringAsFixed(0)}',
            'Top expenses: ${topExpenses.map((e) => '${e.key.label(false)} ¥${e.value.toStringAsFixed(0)}').join(", ")}',
          ];

    final instruction = isZh
        ? '''
请分析以下用户消息，输出 JSON（仅 JSON，不要其他文字）：
{"intent": "投诉|咨询|建议|其他", "emotion": "积极|中性|沮丧|愤怒|紧急", "summary": "一句话摘要（中文）", "reply": "你的回复开头"}

回复要求：先共情，再提供帮助。投诉要致歉，建议要感谢。

账户上下文（仅供参考，不要全部列出来）：
${contextLines.join('\n')}'''
        : '''
Analyze this user message and output JSON (only JSON):
{"intent": "complaint|inquiry|suggestion|other", "emotion": "positive|neutral|frustrated|angry|urgent", "summary": "one-line summary", "reply": "your response opening"}

Be empathetic. Apologize for complaints, thank for suggestions.

Account context (for reference, don't list all):
${contextLines.join('\n')}''';

    return instruction;
  }

  Future<void> _runTriage(String userMessage) async {
    try {
      final prompt = _buildTriagePrompt();
      final result = await _modelService.runStructuredQuery(prompt, userMessage);

      if (result != null) {
        final triage = CSTriageResult.fromJson(result);
        setState(() {
          _triageResult = triage;
          _triaged = true;
        });
      }
    } catch (e) {
      debugPrint('[CUSTOMER_SERVICE] Triage failed: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend({String? presetMessage}) async {
    final text = presetMessage ?? _inputController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isGenerating = true;
    });
    _scrollToBottom();

    // Run triage on first message
    if (!_triaged) {
      await _runTriage(text);
    }

    // Send to chat for the reply
    final responseBuffer = StringBuffer();
    bool firstToken = true;

    try {
      await for (final response in _modelService.sendMessageStream(text)) {
        if (response is TextResponse) {
          final token = response.token.replaceAll('<pad>', '');
          if (token.isEmpty) continue;
          if (firstToken) {
            setState(() => _messages.add(ChatMessage(text: '', isUser: false)));
            firstToken = false;
          }
          responseBuffer.write(token);
          setState(() {
            _messages[_messages.length - 1] =
                ChatMessage(text: responseBuffer.toString(), isUser: false);
          });
          _scrollToBottom();
        }
      }

      if (firstToken) {
        setState(() => _messages.add(ChatMessage(
          text: 'Sorry, I could not process your request.',
          isUser: false,
        )));
      }
    } catch (e) {
      setState(() => _messages.add(ChatMessage(text: 'Error: $e', isUser: false)));
    }

    setState(() => _isGenerating = false);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _modelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.support_agent,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n.customerService),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _triaged = false;
                _triageResult = null;
              });
              _modelService.resetChat();
            },
          ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppStrings l10n) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.customerServiceHint,
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[400])),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_triageResult != null) _buildTriageCard(l10n),
        if (_messages.isEmpty) _buildWelcomeSection(l10n),
        Expanded(
          child: _messages.isEmpty
              ? const SizedBox()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => MessageBubble(message: _messages[i]),
                ),
        ),
        _buildInputBar(l10n),
      ],
    );
  }

  Widget _buildTriageCard(AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    final t = _triageResult!;
    final isZh = widget.locale == 'zh';

    Color intentColor;
    switch (t.intent) {
      case '投诉':
      case 'complaint':
        intentColor = Colors.red;
        break;
      case '咨询':
      case 'inquiry':
        intentColor = Colors.blue;
        break;
      case '建议':
      case 'suggestion':
        intentColor = Colors.green;
        break;
      default:
        intentColor = Colors.grey;
    }

    Color emotionColor;
    switch (t.emotion) {
      case '沮丧':
      case 'frustrated':
        emotionColor = Colors.orange;
        break;
      case '愤怒':
      case 'angry':
        emotionColor = Colors.red;
        break;
      case '紧急':
      case 'urgent':
        emotionColor = Colors.deepOrange;
        break;
      case '积极':
      case 'positive':
        emotionColor = Colors.green;
        break;
      default:
        emotionColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  isZh ? '工单摘要' : 'Ticket Summary',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.primary),
                ),
                const Spacer(),
                Icon(Icons.lock, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(isZh ? '端侧处理' : 'On-device',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _tag(
                    isZh ? '意图' : 'Intent',
                    t.intent,
                    intentColor,
                    cs),
                const SizedBox(width: 8),
                _tag(
                    isZh ? '情绪' : 'Emotion',
                    t.emotion,
                    emotionColor,
                    cs),
              ],
            ),
            const SizedBox(height: 10),
            Text(t.summary,
                style: TextStyle(fontSize: 13, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, String value, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          Text(value,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(Icons.support_agent, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(l10n.customerService,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.customerServiceHint,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.quickQuestions,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            _quickQuestionChip(
                Icons.account_circle_outlined, l10n.accountIssues, l10n),
            const SizedBox(height: 8),
            _quickQuestionChip(
                Icons.credit_card, l10n.cardServices, l10n),
            const SizedBox(height: 8),
            _quickQuestionChip(
                Icons.swap_horiz, l10n.transferHelp, l10n),
            const SizedBox(height: 8),
            _quickQuestionChip(
                Icons.account_balance_outlined, l10n.productInquiry, l10n),
            const SizedBox(height: 8),
            _quickQuestionChip(
                Icons.feedback_outlined, l10n.complaintFeedback, l10n),
          ],
        ),
      ),
    );
  }

  Widget _quickQuestionChip(
      IconData icon, String label, AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: () => _handleQuickQuestion(label, l10n),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style:
                          TextStyle(fontSize: 14, color: cs.onSurface))),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _handleQuickQuestion(String category, AppStrings l10n) {
    String question;
    if (l10n.isZh) {
      switch (category) {
        case '账户问题':
          question = '我的账户遇到了问题，可以帮我看看吗？';
          break;
        case '卡片服务':
          question = '我想咨询一下卡片相关的服务';
          break;
        case '转账帮助':
          question = '我转账的5000元还没到账，请帮我查一下';
          break;
        case '产品咨询':
          question = '我想了解一下你们银行的理财产品';
          break;
        case '投诉建议':
          question = '我对App的速度不太满意，希望能改进';
          break;
        default:
          question = category;
      }
    } else {
      switch (category) {
        case 'Account Issues':
          question = 'I have an issue with my account, can you help?';
          break;
        case 'Card Services':
          question = 'I would like to inquire about card services';
          break;
        case 'Transfer Help':
          question = 'My transfer of 5000 hasn\'t arrived yet, can you check?';
          break;
        case 'Product Inquiry':
          question = 'I would like to know about your wealth management products';
          break;
        case 'Feedback':
          question = 'I\'m not satisfied with the app speed, hope to improve';
          break;
        default:
          question = category;
      }
    }
    _handleSend(presetMessage: question);
  }

  Widget _buildInputBar(AppStrings l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_isGenerating,
              decoration: InputDecoration(
                hintText: l10n.csAskQuestion,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isGenerating ? null : () => _handleSend(),
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
