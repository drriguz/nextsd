import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/chat_message.dart';
import '../services/model_service.dart';
import '../widgets/message_bubble.dart';

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
      await _modelService.initAndLoad(
        'Qwen3-0.6B',
        locale: widget.locale,
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
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

    final responseBuffer = StringBuffer();
    bool firstToken = true;

    try {
      await for (final response in _modelService.sendMessageStream(text)) {
        if (response is TextResponse) {
          if (firstToken) {
            setState(() {
              _messages.add(ChatMessage(text: '', isUser: false));
            });
            firstToken = false;
          }
          responseBuffer.write(response.token);
          setState(() {
            _messages[_messages.length - 1] = ChatMessage(
              text: responseBuffer.toString(),
              isUser: false,
            );
          });
          _scrollToBottom();
        }
      }

      if (firstToken) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, I could not process your request. Please try again.',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: $e',
          isUser: false,
        ));
      });
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
            Icon(Icons.support_agent, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n.customerService),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Chat',
            onPressed: () {
              setState(() => _messages.clear());
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
            Text(l10n.customerServiceHint, style: TextStyle(color: Colors.grey[500])),
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
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[400])),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_messages.isEmpty) _buildWelcomeSection(l10n),
        Expanded(
          child: _messages.isEmpty
              ? const SizedBox()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(message: _messages[index]);
                  },
                ),
        ),
        _buildInputBar(l10n),
      ],
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
            Text(l10n.customerService, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.customerServiceHint, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.quickQuestions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            _quickQuestionChip(Icons.account_circle_outlined, l10n.accountIssues, l10n),
            const SizedBox(height: 8),
            _quickQuestionChip(Icons.credit_card, l10n.cardServices, l10n),
            const SizedBox(height: 8),
            _quickQuestionChip(Icons.swap_horiz, l10n.transferHelp, l10n),
            const SizedBox(height: 8),
            _quickQuestionChip(Icons.account_balance_outlined, l10n.productInquiry, l10n),
            const SizedBox(height: 8),
            _quickQuestionChip(Icons.feedback_outlined, l10n.complaintFeedback, l10n),
          ],
        ),
      ),
    );
  }

  Widget _quickQuestionChip(IconData icon, String label, AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: () => _handleQuickQuestion(label, l10n),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface))),
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
          question = '我需要转账方面的帮助';
          break;
        case '产品咨询':
          question = '我想了解一下你们银行的理财产品';
          break;
        case '投诉建议':
          question = '我有一些建议和反馈想告诉银行';
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
          question = 'I need help with a transfer';
          break;
        case 'Product Inquiry':
          question = 'I would like to know about your wealth management products';
          break;
        case 'Feedback':
          question = 'I have some feedback and suggestions for the bank';
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
                  horizontal: 16,
                  vertical: 10,
                ),
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
