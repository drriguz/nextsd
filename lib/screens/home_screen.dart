import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/tranche.dart';
import '../services/locale_provider.dart';
import '../services/product_service.dart';
import '../widgets/global_search_delegate.dart';
import '../widgets/tranche_card.dart';
import 'chat_screen.dart';
import 'tranche_detail_screen.dart';
import 'transaction_screen.dart';

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
    _loadProducts();
  }

  void _onLocaleChange() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.localeProvider.removeListener(_onLocaleChange);
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
      appBar: AppBar(
        title: Text(l10n.productsOnSale),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.search,
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  tranches: _allTranches ?? [],
                  l10n: l10n,
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
          const TransactionScreen(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: _currentTab == 0
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
            label: l10n.productsOnSale,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.transactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
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

    return Column(
      children: [
        _buildProductTabs(),
        _buildFilterBar(),
        Expanded(
          child: _filteredTranches.isEmpty
              ? Center(
                  child: Text(
                    l10n.noProducts,
                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 80),
                    itemCount: _filteredTranches.length,
                    itemBuilder: (context, index) {
                      return TrancheCard(
                        tranche: _filteredTranches[index],
                        onTap: () => _showTrancheDetail(_filteredTranches[index]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
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
      ],
    );
  }

  void _showTrancheDetail(Tranche tranche) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrancheDetailScreen(tranche: tranche),
      ),
    );
  }
}
