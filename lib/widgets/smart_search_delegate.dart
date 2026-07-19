import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/tranche.dart';
import '../screens/change_password_screen.dart';
import '../screens/customer_service_screen.dart';
import '../screens/transfer_screen.dart';
import '../services/smart_search_service.dart';

class SmartSearchDelegate extends SearchDelegate {
  final AppStrings l10n;
  final String locale;
  final List<Tranche> tranches;
  final Function(int)? onNavigateToTab;

  SmartSearchDelegate({
    required this.l10n,
    required this.locale,
    required this.tranches,
    this.onNavigateToTab,
  });

  @override
  String get searchFieldLabel => l10n.isZh
      ? '输入指令，如"修改密码"'
      : 'Type a command, e.g. "Change password"';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _SmartSearchResults(
      l10n: l10n,
      locale: locale,
      query: query,
      onNavigateToTab: onNavigateToTab,
      onClose: () => close(context, null),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSuggestionsList(context);
    }
    return _buildSearchHint(context);
  }

  Widget _buildSearchHint(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            l10n.isZh ? '按回车键搜索' : 'Press enter to search',
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            '"$query"',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suggestions = l10n.isZh
        ? [
            '修改密码',
            '转账给张三1000元',
            '查看交易记录',
            '联系客服',
            '查看账户',
          ]
        : [
            'Change password',
            'Transfer 1000 to Zhang',
            'View transactions',
            'Contact support',
            'View account',
          ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              l10n.isZh ? '智能搜索 (Qwen3-0.6B)' : 'Smart Search (Qwen3-0.6B)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.isZh ? '试试这些指令：' : 'Try these commands:',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((s) => _buildSuggestionChip(s, context)),
      ],
    );
  }

  Widget _buildSuggestionChip(String suggestion, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          query = suggestion;
          showResults(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Expanded(child: Text(suggestion, style: const TextStyle(fontSize: 14))),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartSearchResults extends StatefulWidget {
  final AppStrings l10n;
  final String locale;
  final String query;
  final Function(int)? onNavigateToTab;
  final VoidCallback onClose;

  const _SmartSearchResults({
    required this.l10n,
    required this.locale,
    required this.query,
    this.onNavigateToTab,
    required this.onClose,
  });

  @override
  State<_SmartSearchResults> createState() => _SmartSearchResultsState();
}

class _SmartSearchResultsState extends State<_SmartSearchResults> {
  final SmartSearchService _searchService = SmartSearchService.instance;
  bool _isLoading = true;
  String? _functionName;
  Map<String, dynamic>? _parameters;
  String? _textResponse;
  String? _error;
  bool _actionExecuted = false;

  @override
  void initState() {
    super.initState();
    _processQuery();
  }

  Future<void> _processQuery() async {
    debugPrint('[SMART_SEARCH_UI] Processing query: "${widget.query}"');
    
    final result = await _searchService.processQuery(widget.query);
    
    debugPrint('[SMART_SEARCH_UI] Result: function=${result.functionName}, text=${result.textResponse}, error=${result.isError}');
    
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _functionName = result.functionName;
      _parameters = result.parameters;
      _textResponse = result.textResponse;
      _error = result.isError ? result.textResponse : null;
    });

    if (_functionName != null && !_actionExecuted) {
      _actionExecuted = true;
      // Delay action execution to ensure the widget is fully built
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _executeAction(_functionName!, _parameters ?? {});
        }
      });
    }
  }

  void _executeAction(String functionName, Map<String, dynamic> parameters) {
    debugPrint('[SMART_SEARCH_UI] Executing action: $functionName with params: $parameters');

    // Capture the NavigatorState BEFORE closing the search delegate.
    // After close(), this widget is disposed (mounted == false) and
    // Navigator.of(context) would fail. The NavigatorState itself
    // belongs to the root navigator and stays valid.
    final navigator = Navigator.of(context);

    // Close the search delegate first
    widget.onClose();

    // Navigate using the captured navigator after the pop completes
    Future.delayed(const Duration(milliseconds: 100), () {
      switch (functionName) {
        case 'change_password':
          navigator.push(
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          );
          break;
        case 'transfer_money':
          navigator.push(
            MaterialPageRoute(
              builder: (_) => TransferScreen(
                transferType: TransferType.others,
                initialAmount: parameters['amount']?.toString(),
                initialRecipient: parameters['recipient']?.toString(),
              ),
            ),
          );
          break;
        case 'view_transactions':
          widget.onNavigateToTab?.call(3);
          break;
        case 'view_products':
          widget.onNavigateToTab?.call(3);
          break;
        case 'contact_support':
          navigator.push(
            MaterialPageRoute(builder: (_) => CustomerServiceScreen(locale: widget.locale)),
          );
          break;
        case 'view_account':
          widget.onNavigateToTab?.call(1);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              widget.l10n.isZh ? '正在理解您的指令...' : 'Understanding your request...',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Model: Qwen3-0.6B',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[400])),
            ],
          ),
        ),
      );
    }

    if (_functionName != null) {
      String actionLabel;
      IconData actionIcon;

      switch (_functionName) {
        case 'change_password':
          actionLabel = widget.l10n.isZh ? '正在打开修改密码...' : 'Opening change password...';
          actionIcon = Icons.lock_outline;
          break;
        case 'transfer_money':
          actionLabel = widget.l10n.isZh ? '正在打开转账...' : 'Opening transfer...';
          actionIcon = Icons.swap_horiz;
          break;
        case 'view_transactions':
          actionLabel = widget.l10n.isZh ? '正在打开交易记录...' : 'Opening transactions...';
          actionIcon = Icons.receipt_long;
          break;
        case 'view_products':
          actionLabel = widget.l10n.isZh ? '正在打开产品列表...' : 'Opening products...';
          actionIcon = Icons.account_balance;
          break;
        case 'contact_support':
          actionLabel = widget.l10n.isZh ? '正在打开客服...' : 'Opening customer service...';
          actionIcon = Icons.support_agent;
          break;
        case 'view_account':
          actionLabel = widget.l10n.isZh ? '正在打开账户...' : 'Opening account...';
          actionIcon = Icons.person;
          break;
        default:
          actionLabel = widget.l10n.isZh ? '正在执行操作...' : 'Executing action...';
          actionIcon = Icons.play_arrow;
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(actionIcon, size: 48, color: cs.primary),
            const SizedBox(height: 16),
            Text(actionLabel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: cs.onSurface)),
          ],
        ),
      );
    }

    if (_textResponse != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  widget.l10n.isZh ? '智能助手回复' : 'Assistant Response',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_textResponse!, style: const TextStyle(fontSize: 15)),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(widget.l10n.noResults, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
