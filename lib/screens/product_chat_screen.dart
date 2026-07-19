import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../models/tranche.dart';
import '../widgets/message_bubble.dart';

const _modelFileName = 'gemma-4-E2B-it.litertlm';
const _externalModelPath = '/sdcard/Download/$_modelFileName';

class ProductChatScreen extends StatefulWidget {
  final Tranche tranche;
  final String locale;

  const ProductChatScreen({
    super.key,
    required this.tranche,
    required this.locale,
  });

  @override
  State<ProductChatScreen> createState() => _ProductChatScreenState();
}

class _ProductChatScreenState extends State<ProductChatScreen> {
  dynamic _model;
  dynamic _chat;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;

  static bool _modelInstalled = false;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<String> _getModelPath() async {
    if (Platform.isAndroid) {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/$_modelFileName';
    }
    return '${Platform.environment['HOME']}/Downloads/$_modelFileName';
  }

  Future<void> _initAndLoad() async {
    try {
      final modelPath = await _getModelPath();

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
        throw StateError('Gemma-4 model not found at $modelPath. '
            'Place $_modelFileName in your Downloads folder.');
      }

      if (!_modelInstalled) {
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        ).fromFile(modelPath).install();
        _modelInstalled = true;
      }

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
      );

      await _createChat();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[PRODUCT_CHAT] Init failed: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _createChat() async {
    final prompt = _buildSystemPrompt(widget.tranche, widget.locale);
    _chat = await _model.createChat(
      systemInstruction: prompt,
      maxOutputTokens: 1024,
      supportsFunctionCalls: false,
    );
  }

  String _buildSystemPrompt(Tranche t, String locale) {
    final isZh = locale == 'zh';

    final productInfo = isZh
        ? '产品名称：${t.productNameCN ?? t.productName}\n'
          '产品类型：${t.product}\n'
          '期次：${t.trancheName}\n'
          '币种：${t.ccy}\n'
          '期限：${t.tenor}\n'
          '${t.coupon != null ? '票息：${t.coupon}%\n' : ''}'
          '${t.couponFreq != null ? '票息频率：${t.couponFreq}\n' : ''}'
          '${t.principalProtection != null ? '本金保障：${t.formattedProtection}\n' : ''}'
          '${t.strike != null && t.strike != '0' ? '执行价：${t.strike}%\n' : ''}'
          '${t.ki != null && t.ki != '0' ? '敲入价：${t.ki}%\n' : ''}'
          '${t.ko != null && t.ko != '0' ? '敲出价：${t.ko}%\n' : ''}'
          '风险评级：PRR ${t.prr ?? '-'}\n'
          '${t.underlyingName != null && t.underlyingName!.isNotEmpty ? '挂钩标的：${t.underlyingName!.join(', ')}\n' : ''}'
          '${t.issuer != null ? '发行人：${t.issuer}\n' : ''}'
          '${t.minOrder != null ? '最低投资额：${t.ccy} ${t.formattedMinOrder}\n' : ''}'
          '${t.eligibleSegments != null ? '适用客群：${t.eligibleSegments}\n' : ''}'
          '产品状态：${t.status}\n'
          '${t.windowPeriodStartDate != null && t.windowPeriodEndDate != null ? '认购期：${t.windowPeriodStartDate} - ${t.windowPeriodEndDate}\n' : ''}'
          '${t.minReturnPA != null ? '最低年化收益：${t.minReturnPA}\n' : ''}'
          '${t.maxReturnPA != null ? '最高年化收益：${t.maxReturnPA}\n' : ''}'
        : 'Product Name: ${t.productNameCN ?? t.productName}\n'
          'Product Type: ${t.product}\n'
          'Tranche: ${t.trancheName}\n'
          'Currency: ${t.ccy}\n'
          'Tenor: ${t.tenor}\n'
          '${t.coupon != null ? 'Coupon: ${t.coupon}%\n' : ''}'
          '${t.couponFreq != null ? 'Coupon Frequency: ${t.couponFreq}\n' : ''}'
          '${t.principalProtection != null ? 'Principal Protection: ${t.formattedProtection}\n' : ''}'
          '${t.strike != null && t.strike != '0' ? 'Strike: ${t.strike}%\n' : ''}'
          '${t.ki != null && t.ki != '0' ? 'KI Barrier: ${t.ki}%\n' : ''}'
          '${t.ko != null && t.ko != '0' ? 'KO Barrier: ${t.ko}%\n' : ''}'
          'Risk Rating: PRR ${t.prr ?? '-'}\n'
          '${t.underlyingName != null && t.underlyingName!.isNotEmpty ? 'Underlying: ${t.underlyingName!.join(', ')}\n' : ''}'
          '${t.issuer != null ? 'Issuer: ${t.issuer}\n' : ''}'
          '${t.minOrder != null ? 'Min Order: ${t.ccy} ${t.formattedMinOrder}\n' : ''}'
          '${t.eligibleSegments != null ? 'Eligible Segments: ${t.eligibleSegments}\n' : ''}'
          'Status: ${t.status}\n'
          '${t.windowPeriodStartDate != null && t.windowPeriodEndDate != null ? 'Subscription Period: ${t.windowPeriodStartDate} - ${t.windowPeriodEndDate}\n' : ''}'
          '${t.minReturnPA != null ? 'Min Return p.a.: ${t.minReturnPA}\n' : ''}'
          '${t.maxReturnPA != null ? 'Max Return p.a.: ${t.maxReturnPA}\n' : ''}';

    final instruction = isZh
        ? '你是银行产品顾问。客户正在咨询这款结构性存款产品。请基于上述产品信息准确回答客户问题。回答要专业、简洁、有帮助。使用中文。'
        : 'You are a banking product advisor. Answer questions about this structured deposit product accurately based on the product information above. Be professional, concise, and helpful.';

    return '$instruction\n\n$productInfo';
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

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isGenerating = true;
    });
    _scrollToBottom();

    try {
      await _chat.addQuery(Message.text(text: text, isUser: true));

      final responseBuffer = StringBuffer();
      bool firstToken = true;

      await for (final response in _chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          if (firstToken) {
            setState(() => _messages.add(ChatMessage(text: '', isUser: false)));
            firstToken = false;
          }
          responseBuffer.write(response.token);
          setState(() {
            _messages[_messages.length - 1] =
                ChatMessage(text: responseBuffer.toString(), isUser: false);
          });
          _scrollToBottom();
        }
      }

      if (firstToken) {
        setState(() => _messages.add(ChatMessage(
          text: 'No response. Please try again.',
          isUser: false,
        )));
      }
    } catch (e) {
      setState(() => _messages.add(ChatMessage(
        text: 'Error: $e',
        isUser: false,
      )));
    }

    setState(() => _isGenerating = false);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _chat = null;
    _model?.close();
    _model = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Product Advisor',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              l10n.productTypeName(widget.tranche.productNameCN, widget.tranche.product),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Chat',
            onPressed: _isLoading
                ? null
                : () {
                    setState(() => _messages.clear());
                    _createChat();
                  },
          ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppStrings l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                  style: TextStyle(color: Colors.red[400], fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_messages.isEmpty) _buildEmptyState(l10n),
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

  Widget _buildEmptyState(AppStrings l10n) {
    final isZh = widget.locale == 'zh';
    final questions = isZh
        ? [
            '这个产品的风险等级是什么？',
            '保本机制是怎样的？',
            '适合什么类型的投资者？',
            '挂钩标的如何影响收益？',
          ]
        : [
            'What is the risk rating of this product?',
            'How does the principal protection work?',
            'What type of investor is this suitable for?',
            'How do the underlying assets affect returns?',
          ];

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(Icons.chat_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isZh ? '向 AI 顾问咨询此产品' : 'Ask the AI advisor about this product',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ...questions.map((q) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      _inputController.text = q;
                      _handleSend();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.help_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(q, style: const TextStyle(fontSize: 14)),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
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
                hintText: l10n.isZh ? '输入产品相关问题...' : 'Ask about this product...',
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
            onPressed: _isGenerating ? null : _handleSend,
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
