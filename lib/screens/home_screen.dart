import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/tranche.dart';
import '../services/locale_provider.dart';
import '../services/product_service.dart';
import '../widgets/tranche_card.dart';
import 'chat_screen.dart';

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
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildHomeTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
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
    final l10n = l;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.productTypeName(tranche.productNameCN, tranche.product),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(tranche.trancheName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 16),
                  _detailSection(l10n.productDetails, {
                    l10n.detailLabel('Product Type'): tranche.product,
                    l10n.detailLabel('Currency'): '${l10n.currencyName(tranche.ccy)} (${tranche.ccy})',
                    l10n.detailLabel('Tenor'): l10n.formatTenor(tranche.tenor),
                    if (tranche.coupon != null) l10n.detailLabel('Coupon'): '${tranche.coupon}%',
                    if (tranche.couponFreq != null) l10n.detailLabel('Coupon Frequency'): tranche.couponFreq!,
                    if (tranche.principalProtection != null) l10n.detailLabel('Principal Protection'): tranche.formattedProtection,
                    if (tranche.strike != null && tranche.strike != '0') l10n.detailLabel('Strike'): '${tranche.strike}%',
                    if (tranche.ki != null && tranche.ki != '0') l10n.detailLabel('KI Barrier'): '${tranche.ki}%',
                    if (tranche.ko != null && tranche.ko != '0') l10n.detailLabel('KO Barrier'): '${tranche.ko}%',
                    if (tranche.prr != null) l10n.detailLabel('Risk Rating'): 'PRR ${tranche.prr}',
                  }),
                  _detailSection(l10n.subscription, {
                    l10n.detailLabel('Subscription Period'): l10n.formatSubscriptionPeriod(tranche.windowPeriodStartDate, tranche.windowPeriodEndDate),
                    if (tranche.minOrder != null) l10n.detailLabel('Min Order'): '${l10n.currencyName(tranche.ccy)} ${tranche.formattedMinOrder}',
                    if (tranche.denomination != null) l10n.detailLabel('Denomination'): tranche.denomination!,
                    if (tranche.eligibleSegments != null) l10n.detailLabel('Eligible Segments'): tranche.eligibleSegments!,
                    if (tranche.eligibleCities != null) l10n.detailLabel('Eligible Cities'): tranche.eligibleCities!,
                    if (tranche.issuer != null) l10n.detailLabel('Issuer'): tranche.issuer!,
                    if (tranche.openToQI != null) l10n.detailLabel('Open to QI'): tranche.openToQI!,
                  }),
                  if (tranche.underlyingName != null && tranche.underlyingName!.isNotEmpty)
                    _detailSection(l10n.underlying, {
                      for (var i = 0; i < tranche.underlyingName!.length; i++)
                        tranche.underlyingName![i]: tranche.underlying != null && i < tranche.underlying!.length
                            ? tranche.underlying![i]
                            : '',
                    }),
                  if (tranche.minReturnPA != null || tranche.maxReturnPA != null)
                    _detailSection(l10n.returns, {
                      if (tranche.minReturnPA != null) l10n.detailLabel('Min Return p.a.'): tranche.minReturnPA!,
                      if (tranche.maxReturnPA != null) l10n.detailLabel('Max Return p.a.'): tranche.maxReturnPA!,
                      if (tranche.barrierReturnPA != null) l10n.detailLabel('Barrier Return p.a.'): tranche.barrierReturnPA!,
                      if (tranche.barrierPercent != null) l10n.detailLabel('Barrier Level'): '${tranche.barrierPercent}%',
                      if (tranche.participationRate != null) l10n.detailLabel('Participation Rate'): '${tranche.participationRate}%',
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailSection(String title, Map<String, String> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: entries.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(e.key, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(e.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
