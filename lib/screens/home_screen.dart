import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/daily_transaction.dart';
import '../models/tranche.dart';
import '../services/financial_summary_service.dart';
import '../services/locale_provider.dart';
import '../services/product_service.dart';
import '../services/smart_search_service.dart';
import '../widgets/smart_search_delegate.dart';
import '../widgets/tranche_card.dart';
import 'chat_screen.dart';
import 'change_password_screen.dart';
import 'customer_service_screen.dart';
import 'tranche_detail_screen.dart';
import 'transfer_screen.dart';

class HomeScreen extends StatefulWidget {
  final LocaleProvider localeProvider;

  const HomeScreen({super.key, required this.localeProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  int _productTab = 0;
  final ProductService _productService = ProductService();
  List<Tranche>? _allTranches;
  List<Tranche> _filteredTranches = [];
  bool _loading = true;
  String? _error;

  String _selectedModel = 'Qwen3-0.6B';
  final List<String> _availableModels = ['Qwen3-0.6B', 'Gemma-4', 'Llama-3.2-3B'];

  String? _filterSegment;
  final List<String> _availableSegments = [
    'Private',
    'Priority',
    'Premium',
    'Personal',
  ];

  AppStrings get l => AppStrings(widget.localeProvider);

  @override
  void initState() {
    super.initState();
    widget.localeProvider.addListener(_onLocaleChange);
    MockTransactionGenerator.instance.generate();
    _loadProducts();
    _initSmartSearch();
    _initFinancialSummary();
  }

  Future<void> _initSmartSearch() async {
    try {
      await SmartSearchService.instance.initModel();
    } catch (e) {
      debugPrint('Smart search init failed: $e');
    }
  }

  Future<void> _initFinancialSummary() async {
    try {
      await FinancialSummaryService.instance.initAndGenerate(
        isZh: widget.localeProvider.locale == 'zh',
      );
    } catch (e) {
      debugPrint('Financial summary init failed: $e');
    }
  }

  void _onLocaleChange() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.localeProvider.removeListener(_onLocaleChange);
    SmartSearchService.instance.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final tranches = await _productService.loadProducts();
      setState(() {
        _allTranches = tranches;
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilters() {
    if (_allTranches == null) return;

    var list = _allTranches!;

    if (_productTab == 0) {
      list = list.where((t) => t.isOpen).toList();
    } else {
      list = list.where((t) => t.isComingSoon).toList();
    }

    if (_filterSegment != null) {
      list = list.where((t) {
        return t.eligibleSegments != null &&
            t.eligibleSegments!.toLowerCase().contains(_filterSegment!.toLowerCase());
      }).toList();
    }

    setState(() => _filteredTranches = list);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l;
    return Scaffold(
      appBar: _currentTab == 4 ? null : AppBar(
        title: _getAppBarTitle(l10n),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.search,
            onPressed: () {
              showSearch(
                context: context,
                delegate: SmartSearchDelegate(
                  l10n: l10n,
                  locale: widget.localeProvider.locale,
                  tranches: _allTranches ?? [],
                  onNavigateToTab: (tab) => setState(() => _currentTab = tab),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildHomeTab(),
          _buildMyTab(),
          _buildTransferTab(),
          _buildWealthTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: _currentTab == 3
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      modelName: _selectedModel,
                      locale: widget.localeProvider.locale,
                      tranches: _allTranches ?? [],
                    ),
                  ),
                );
              },
              tooltip: 'AI Assistant',
              child: const Icon(Icons.chat),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.tabMy,
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz),
            selectedIcon: const Icon(Icons.swap_horiz),
            label: l10n.tabTransfer,
          ),
          NavigationDestination(
            icon: const Icon(Icons.trending_up),
            selectedIcon: const Icon(Icons.trending_up),
            label: l10n.tabWealth,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }

  Widget? _getAppBarTitle(AppStrings l10n) {
    switch (_currentTab) {
      case 0:
        return Text(l10n.tabHome);
      case 1:
        return Text(l10n.tabMy);
      case 2:
        return Text(l10n.tabTransfer);
      case 3:
        return Text(l10n.tabWealth);
      default:
        return null;
    }
  }

  // ==================== HOME TAB ====================

  Widget _buildHomeTab() {
    final l10n = l;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildWelcomeHero(l10n),
        _buildAiSummaryCard(l10n),
        _buildQuickActionsGrid(l10n),
        _buildRecentTransactions(l10n),
      ],
    );
  }

  Widget _buildAiSummaryCard(AppStrings l10n) {
    return AnimatedBuilder(
      animation: FinancialSummaryService.instance,
      builder: (context, _) {
        final service = FinancialSummaryService.instance;
        final cs = Theme.of(context).colorScheme;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.tertiaryContainer.withValues(alpha: 0.5),
                cs.primaryContainer.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.weeklySummaryTitle,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
                  ),
                  const Spacer(),
                  if (service.generated && !service.isGenerating)
                    GestureDetector(
                      onTap: () => service.regenerate(isZh: l10n.isZh),
                      child: Icon(Icons.refresh, size: 18, color: cs.primary),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (service.isGenerating) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.generatingSummary,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ] else if (service.summary != null) ...[
                Text(
                  service.summary!,
                  style: TextStyle(fontSize: 14, height: 1.5, color: cs.onSurface),
                ),
              ] else ...[
                Text(
                  l10n.summaryUnavailable,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHero(AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.welcomeBack, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                  const Text('John Chen', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(l10n.totalAssets, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 4),
          const Text('CNY 12,580,000.00', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _heroStat(l10n.accountBalance, 'CNY 2,350,000.00'),
              const SizedBox(width: 24),
              _heroStat(l10n.tabWealth, 'CNY 10,230,000.00'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuickActionsGrid(AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      _GridItem(Icons.account_balance, l10n.structuredDeposit, cs.primaryContainer, () {
        setState(() => _currentTab = 3);
      }),
      _GridItem(Icons.pie_chart_outline, l10n.fund, Colors.orange[50]!, () {}),
      _GridItem(Icons.currency_exchange, l10n.foreignExchange, Colors.green[50]!, () {}),
      _GridItem(Icons.shield_outlined, l10n.insurance, Colors.blue[50]!, () {}),
      _GridItem(Icons.description_outlined, l10n.bonds, Colors.purple[50]!, () {}),
      _GridItem(Icons.support_agent, l10n.customerService, Colors.teal[50]!, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerServiceScreen(locale: widget.localeProvider.locale)));
      }),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.quickActions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildGridItem(item, cs);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(_GridItem item, ColorScheme cs) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 28, color: cs.primary),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(AppStrings l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.transactions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => setState(() => _currentTab = 3),
                child: Text(l10n.more, style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _mockRecentTransaction('WoB Autocall AAPL+MSFT', 'CNY 1,000,000', 'Active', Colors.green),
          _mockRecentTransaction('HSI Snowball 2025-02', 'HKD 2,000,000', 'Active', Colors.green),
          _mockRecentTransaction('EUR/USD Range Accrual', 'USD 500,000', 'Matured', Colors.blue),
        ],
      ),
    );
  }

  Widget _mockRecentTransaction(String name, String amount, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.receipt_long, size: 18, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(amount, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
        ),
      ),
    );
  }

  // ==================== MY TAB ====================

  Widget _buildMyTab() {
    final l10n = l;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.person, size: 40, color: cs.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'John Chen',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.premiumClient('Priority'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.verified,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.myAccounts, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildAccountCard(l10n.savings, Icons.account_balance_wallet, 'CNY 2,350,000.00', '**** 8888', cs),
        const SizedBox(height: 8),
        _buildAccountCard(l10n.fixedDeposits, Icons.lock_outline, 'CNY 5,000,000.00', '${l10n.maturity}: 2026-01-15', cs),
        const SizedBox(height: 8),
        _buildAccountCard(l10n.investments, Icons.trending_up, 'CNY 10,230,000.00', '3 ${l10n.activePositions}', cs),
        const SizedBox(height: 24),
        Text(l10n.quickServices, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _serviceButton(Icons.lock_outline, l10n.changePassword, () => _showChangePasswordDialog(), cs)),
            const SizedBox(width: 12),
            Expanded(child: _serviceButton(Icons.receipt_outlined, l10n.statement, () {}, cs)),
            const SizedBox(width: 12),
            Expanded(child: _serviceButton(Icons.credit_card, l10n.cardCenter, () {}, cs)),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountCard(String title, IconData icon, String amount, String subtitle, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _serviceButton(IconData icon, String label, VoidCallback onTap, ColorScheme cs) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: cs.primary),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ==================== TRANSFER TAB ====================

  Widget _buildTransferTab() {
    final l10n = l;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _transferTypeCard(Icons.swap_horiz, l10n.transferToOwn, cs, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen(transferType: TransferType.own)));
            })),
            const SizedBox(width: 12),
            Expanded(child: _transferTypeCard(Icons.person_outline, l10n.transferToOthers, cs, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen(transferType: TransferType.others)));
            })),
            const SizedBox(width: 12),
            Expanded(child: _transferTypeCard(Icons.public, l10n.internationalTransfer, cs, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen(transferType: TransferType.international)));
            })),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.transferHistory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _mockTransferHistory('To: Zhang Wei', 'CNY 50,000.00', '2025-07-18'),
        _mockTransferHistory('To: Self (USD)', 'USD 10,000.00', '2025-07-15'),
        _mockTransferHistory('To: Li Ming', 'CNY 120,000.00', '2025-07-10'),
      ],
    );
  }

  Widget _transferTypeCard(IconData icon, String label, ColorScheme cs, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: cs.primary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _mockTransferHistory(String to, String amount, String date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          child: Icon(Icons.send, size: 18, color: Theme.of(context).colorScheme.onTertiaryContainer),
        ),
        title: Text(to, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        trailing: Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ==================== WEALTH TAB ====================

  Widget _buildWealthTab() {
    final l10n = l;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.loadingFailed}: $_error', style: TextStyle(color: Colors.red[400], fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadProducts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        _buildWealthHeader(l10n),
        _buildWeeklySummary(l10n),
        _buildRecentDailyTransactions(l10n),
        _buildProductTabs(),
        _buildFilterBar(),
        ..._filteredTranches.map((t) => TrancheCard(
          tranche: t,
          onTap: () => _showTrancheDetail(t),
        )),
        if (_filteredTranches.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                l10n.noProducts,
                style: TextStyle(color: Colors.grey[500], fontSize: 15),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWealthHeader(AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.myInvestments, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('CNY 10,230,000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () {},
            child: Text(l10n.browseProducts),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary(AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    final summary = MockTransactionGenerator.instance.weeklySummary;
    final topExpenses = summary.topExpenseCategories;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _summaryStat(l10n.weeklyIncome, summary.totalIncome, Colors.green, cs)),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(child: _summaryStat(l10n.weeklyExpense, summary.totalExpense, Colors.red, cs)),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(child: _summaryStat(l10n.weeklyNet, summary.netCashFlow, summary.netCashFlow >= 0 ? Colors.green : Colors.red, cs)),
            ],
          ),
          if (topExpenses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.expenseBreakdown, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: topExpenses.map((e) {
                final txn = DailyTransaction(
                  id: '', date: DateTime.now(), description: '', amount: 0, type: TransactionType.expense, category: e.key,
                );
                final label = l10n.isZh ? txn.categoryName : txn.categoryNameEn;
                final pct = (e.value / summary.totalExpense * 100).toStringAsFixed(0);
                return Chip(
                  label: Text('$label ${_formatAmount(e.value)} ($pct%)', style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryStat(String label, double amount, Color color, ColorScheme cs) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          '¥${_formatAmount(amount)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildRecentDailyTransactions(AppStrings l10n) {
    final transactions = MockTransactionGenerator.instance.transactions.take(10).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.recentTransactions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () {},
                child: Text(l10n.viewAll, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...transactions.map((txn) => _buildTransactionTile(txn, l10n)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(DailyTransaction txn, AppStrings l10n) {
    final isIncome = txn.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = _getCategoryIcon(txn.category);
    final label = l10n.isZh ? txn.categoryName : txn.categoryNameEn;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (txn.merchant != null)
                  Text(txn.merchant!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}¥${_formatAmount(txn.amount)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
              ),
              Text(
                '${txn.date.month}/${txn.date.day} ${txn.date.hour.toString().padLeft(2, '0')}:${txn.date.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.salary:
        return Icons.work;
      case TransactionCategory.bonus:
        return Icons.card_giftcard;
      case TransactionCategory.investment:
        return Icons.trending_up;
      case TransactionCategory.transferIn:
        return Icons.call_received;
      case TransactionCategory.dining:
        return Icons.restaurant;
      case TransactionCategory.shopping:
        return Icons.shopping_bag;
      case TransactionCategory.transport:
        return Icons.directions_car;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.utilities:
        return Icons.bolt;
      case TransactionCategory.healthcare:
        return Icons.local_hospital;
      case TransactionCategory.education:
        return Icons.school;
      case TransactionCategory.travel:
        return Icons.flight;
      case TransactionCategory.transferOut:
        return Icons.call_made;
      case TransactionCategory.other:
        return Icons.more_horiz;
    }
  }

  String _formatAmount(double amount) {
    final s = amount.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    if (amount != amount.truncateToDouble()) {
      buf.write('.${(amount - amount.truncate()).toStringAsFixed(2).substring(2)}');
    }
    return buf.toString();
  }

  Widget _buildProductTabs() {
    final l10n = l;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _buildTabChip(l10n.productsOnSale, 0, cs),
          const SizedBox(width: 8),
          _buildTabChip(l10n.comingSoon, 1, cs),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int index, ColorScheme cs) {
    final isSelected = _productTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _productTab = index);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final l10n = l;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showFilterSheet(cs),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(l10n.filter, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _filterSegment != null ? l10n.filterBy(_filterSegment!) : l10n.filterAll,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const Spacer(),
          Text(
            l10n.productCount(_filteredTranches.length),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(ColorScheme cs) {
    final l10n = l;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.filterTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSegments.map((seg) {
                  final isSelected = _filterSegment == seg;
                  return ChoiceChip(
                    label: Text(l10n.isZh ? l10n.segmentZh(seg) : seg),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filterSegment = selected ? seg : null;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              if (_filterSegment != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() => _filterSegment = null);
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  child: Text(l10n.clearFilter),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ==================== SETTINGS TAB ====================

  Widget _buildSettingsTab() {
    final l10n = l;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.premiumClient('Priority'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.segmentLabel('Priority'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.verified,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(l10n.accountInfo, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(l10n.clientId),
                subtitle: const Text('CN-12345678'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(l10n.preferredLanguage),
                subtitle: const Text('English / 中文'),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'zh', label: Text('中文')),
                    ButtonSegment(value: 'en', label: Text('EN')),
                  ],
                  selected: {widget.localeProvider.locale},
                  onSelectionChanged: (value) {
                    widget.localeProvider.setLocale(value.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(l10n.eligibleCities),
                subtitle: const Text('Shanghai, Beijing, Shenzhen'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.settings, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.changePassword),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showChangePasswordDialog(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(l10n.notificationSettings),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: Text(l10n.biometric),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(l10n.helpCenter),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutUs),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.modelSelection, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        Card(
          child: RadioGroup<String>(
            groupValue: _selectedModel,
            onChanged: (value) {
              if (value != null) setState(() => _selectedModel = value);
            },
            child: Column(
              children: _availableModels.map((model) {
                return RadioListTile<String>(
                  title: Text(model),
                  subtitle: Text(model == 'Qwen3-0.6B' ? l10n.defaultLabel : l10n.comingSoonLabel),
                  value: model,
                  toggleable: false,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Text(l10n.logout),
          ),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

  void _showTrancheDetail(Tranche tranche) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrancheDetailScreen(
          tranche: tranche,
          locale: widget.localeProvider.locale,
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }
}

class _GridItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _GridItem(this.icon, this.label, this.color, this.onTap);
}
