import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/model_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ModelService _modelService = ModelService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    setState(() => _isLoading = true);

    try {
      await _modelService.loadModel(
        onStatus: (s) => _updateLastSystemMessage(s),
      );
      _addSystemMessage('Model ready. Ask me anything about Structured Deposits!');
    } catch (e) {
      _addSystemMessage('Tap the download button to get the Gemma 4 E4B model.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _updateLastSystemMessage(String text) {
    if (_messages.isNotEmpty && !_messages.last.isUser) {
      setState(() {
        _messages[_messages.length - 1] = ChatMessage(text: text, isUser: false);
      });
    } else {
      _addSystemMessage(text);
    }
    _scrollToBottom();
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

  Future<void> _handleDownload() async {
    setState(() => _isLoading = true);
    _addSystemMessage('Checking permissions...');

    try {
      final hasPermission = await _modelService.checkStoragePermission();
      if (!hasPermission) {
        _addSystemMessage('Storage permission required. Please grant "All files access" in Settings.');
        setState(() => _isLoading = false);
        _showPermissionDialog();
        return;
      }

      _addSystemMessage('Loading model...');

      await _modelService.installModel(
        onProgress: (p) {
          _updateLastSystemMessage(
            'Downloading: ${p.toStringAsFixed(1)}%',
          );
        },
        onStatus: (s) => _updateLastSystemMessage(s),
      );

      await _modelService.loadModel(
        onStatus: (s) => _updateLastSystemMessage(s),
      );

      _addSystemMessage('Model ready! Ask me anything about Structured Deposits.');
    } catch (e) {
      _addSystemMessage('Failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'This app needs "All files access" to read the model file from your Downloads folder.\n\n'
          'Please enable it in Settings > Apps > nextsd > Permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _modelService.openStorageSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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
      final responseBuffer = StringBuffer();
      bool firstToken = true;

      await for (final token in _modelService.sendMessageStream(text)) {
        if (firstToken) {
          setState(() {
            _messages.add(ChatMessage(text: '', isUser: false));
          });
          firstToken = false;
        }
        responseBuffer.write(token);
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            text: responseBuffer.toString(),
            isUser: false,
          );
        });
        _scrollToBottom();
      }

      if (firstToken) {
        _addSystemMessage('No response generated.');
      }
    } catch (e) {
      _addSystemMessage('Error generating response: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
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
        title: const Text('Structured Deposit Assistant'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_modelService.isModelReady && !_isLoading)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download Model',
              onPressed: _handleDownload,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Chat',
            onPressed: () {
              setState(() => _messages.clear());
              _modelService.resetChat();
              _addSystemMessage('Chat reset. Ask me anything about Structured Deposits!');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading && !_modelService.isModelReady)
            LinearProgressIndicator(value: _modelService.downloadProgress > 0 ? _modelService.downloadProgress : null),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Download the model to start chatting',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
                    enabled: _modelService.isModelReady && !_isGenerating,
                    decoration: InputDecoration(
                      hintText: _modelService.isModelReady
                          ? 'Ask about Structured Deposits...'
                          : 'Download model first',
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
      ),
    );
  }
}
