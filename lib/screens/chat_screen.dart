import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../main.dart';
import '../models/chat_message.dart';
import '../models/tranche.dart';
import '../services/model_service.dart';
import '../widgets/message_bubble.dart';
import 'termsheet_screen.dart';

List<Tool> _buildTools(List<Tranche> tranches) {
  final codes = tranches.map((t) => t.trancheName).toList();
  return [
    Tool(
      name: 'list_products',
      description: 'List all available Structured Deposit products. Returns product codes with basic metadata (currency, tenor, coupon, issuer).',
    ),
    Tool(
      name: 'get_product_detail',
      description: 'Get detailed information for a specific product by its tranche code.',
      parameters: {
        'type': 'object',
        'properties': {
          'code': {
            'type': 'string',
            'description': 'The tranche code (e.g. MALI260702A85P001E). Available codes: ${codes.join(", ")}',
          },
        },
        'required': ['code'],
      },
    ),
    Tool(
      name: 'open_termsheet',
      description: 'Open the term sheet document for a specific product by its tranche code.',
      parameters: {
        'type': 'object',
        'properties': {
          'code': {
            'type': 'string',
            'description': 'The tranche code (e.g. MALI260702A85P001E). Available codes: ${codes.join(", ")}',
          },
        },
        'required': ['code'],
      },
    ),
  ];
}

class ChatScreen extends StatefulWidget {
  final String modelName;
  final String locale;
  final List<Tranche> tranches;

  const ChatScreen({
    super.key,
    required this.modelName,
    required this.locale,
    required this.tranches,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
        _error = 'On-device LLM is not supported on this platform.\n'
            'The LiteRT LM engine requires Apple Silicon (arm64) on macOS.';
      });
      return;
    }

    try {
      final tools = _buildTools(widget.tranches);
      await _modelService.initAndLoad(
        widget.modelName,
        locale: widget.locale,
        tools: tools,
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

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isGenerating = true;
    });
    _scrollToBottom();

    final initialMessageCount = _messages.length;
    await _processResponse(_modelService.sendMessageStream(text));

    final newMessages = _messages.length - initialMessageCount;
    if (newMessages == 0) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'No response. The conversation may have exceeded the context limit. Tap the refresh icon to start a new chat.',
          isUser: false,
        ));
      });
    }

    debugPrint('[CHAT] _handleSend: stream completed');
    setState(() => _isGenerating = false);
  }

  Future<void> _processResponse(Stream<ModelResponse> stream) async {
    final responseBuffer = StringBuffer();
    bool firstToken = true;
    int responseIdx = 0;

    try {
      await for (final response in stream) {
        responseIdx++;
        debugPrint('[CHAT] response #$responseIdx: ${response.runtimeType}');

        if (response is TextResponse) {
          final tokenPreview = response.token.length > 50
              ? '${response.token.substring(0, 50)}...'
              : response.token;
          debugPrint('[CHAT]   text token: "$tokenPreview"');
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
        } else if (response is FunctionCallResponse) {
          debugPrint('[CHAT]   function call: name=${response.name}, args=${response.args}');
          _removeEmptyBubble();
          await _handleFunctionCall(response);
        } else if (response is ParallelFunctionCallResponse) {
          debugPrint('[CHAT]   parallel calls: ${response.calls.length}');
          _removeEmptyBubble();
          for (final call in response.calls) {
            await _handleFunctionCall(call);
          }
          _scrollToBottom();
        }
      }
      debugPrint('[CHAT] stream ended normally after $responseIdx responses');
    } catch (e, s) {
      debugPrint('[CHAT] stream error: $e');
      debugPrint('[CHAT] stack: $s');
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: $e',
          isUser: false,
        ));
      });
    }
  }

  void _removeEmptyBubble() {
    if (_messages.isNotEmpty && !_messages.last.isUser && _messages.last.text.trim().isEmpty) {
      _messages.removeLast();
    }
  }

  Future<void> _handleFunctionCall(FunctionCallResponse call) async {
    debugPrint('[CHAT] _handleFunctionCall: ${call.name}(${call.args})');

    setState(() {
      _messages.add(ChatMessage(
        text: '🔧 Calling ${call.name}...',
        isUser: false,
      ));
    });

    final result = await _executeTool(call);
    final preview = result.length > 100 ? '${result.substring(0, 100)}...' : result;
    debugPrint('[CHAT]   tool result (${result.length} chars): $preview');

    setState(() {
      _messages.add(ChatMessage(
        text: result,
        isUser: false,
      ));
    });

    _scrollToBottom();

    await _modelService.resetChat();
    debugPrint('[CHAT]   chat reset after tool call');
  }

  Future<String> _executeTool(FunctionCallResponse call) async {
    switch (call.name) {
      case 'list_products':
        return _listProducts();
      case 'get_product_detail':
        return _getProductDetail(call.args['code'] as String? ?? '');
      case 'open_termsheet':
        return _openTermsheet(call.args['code'] as String? ?? '');
      default:
        return 'Unknown tool: ${call.name}';
    }
  }

  String _listProducts() {
    final items = <String>[];
    for (final t in widget.tranches) {
      items.add('${t.trancheName}|${t.ccy}|${t.tenor}|${t.coupon ?? "-"}%|${t.issuer ?? "-"}');
    }
    return json.encode({'count': items.length, 'items': items.join('\n')});
  }

  String _getProductDetail(String code) {
    final t = widget.tranches.where((t) => t.trancheName == code);
    if (t.isEmpty) return 'Product not found: $code';

    final tranche = t.first;
    final detail = json.encode({
      'trancheName': tranche.trancheName,
      'productName': tranche.productName,
      'productNameCN': tranche.productNameCN,
      'product': tranche.product,
      'ccy': tranche.ccy,
      'tenor': tranche.tenor,
      'coupon': tranche.coupon,
      'couponFreq': tranche.couponFreq,
      'principalProtection': tranche.principalProtection,
      'issuer': tranche.issuer,
      'status': tranche.status,
      'underlying': tranche.underlying,
      'underlyingName': tranche.underlyingName,
      'strike': tranche.strike,
      'ki': tranche.ki,
      'ko': tranche.ko,
      'minOrder': tranche.minOrder,
      'eligibleSegments': tranche.eligibleSegments,
      'eligibleCities': tranche.eligibleCities,
      'windowPeriodStartDate': tranche.windowPeriodStartDate,
      'windowPeriodEndDate': tranche.windowPeriodEndDate,
      'prr': tranche.prr,
      'minReturnPA': tranche.minReturnPA,
      'maxReturnPA': tranche.maxReturnPA,
    });
    return detail;
  }

  String _openTermsheet(String code) {
    final t = widget.tranches.where((t) => t.trancheName == code);
    final found = t.isNotEmpty;
    final tranche = found ? t.first : null;
    final name = found ? t.first.trancheName : code;

    if (tranche != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TermsSheetScreen(tranche: tranche)),
      );
    }

    return json.encode({'status': 'opened', 'tranche': name});
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modelName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[400], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'Ask me anything about Structured Deposits!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(message: _messages[index]);
                  },
                ),
        ),
        Container(
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
                    hintText: 'Ask about Structured Deposits...',
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
        ),
      ],
    );
  }
}
