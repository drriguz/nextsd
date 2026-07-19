import 'package:flutter/material.dart';
import '../models/tranche.dart';
import '../services/product_service.dart';
import '../widgets/tranche_card.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    '合格投资者',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load: $_error', style: TextStyle(color: Colors.red[400], fontSize: 14)),
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
                    'No products available',
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _buildTabChip('在售产品', 0, cs),
          const SizedBox(width: 8),
          _buildTabChip('即将开售', 1, cs),
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
                  Text('筛选', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _filterSegment != null ? '筛选: $_filterSegment' : '筛选: 全部',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const Spacer(),
          Text(
            '${_filteredTranches.length}个产品',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(ColorScheme cs) {
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
              Text('筛选投资者类型', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSegments.map((seg) {
                  final isSelected = _filterSegment == seg;
                  return ChoiceChip(
                    label: Text(seg),
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
                  child: const Text('清除筛选'),
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
          'Premium Banking Client',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Segment: Priority',
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
              'Verified',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text('Account Info', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Client ID'),
                subtitle: const Text('CN-12345678'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Preferred Language'),
                subtitle: const Text('English / 中文'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Eligible Cities'),
                subtitle: const Text('Shanghai, Beijing, Shenzhen'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Model Selection', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
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
                  subtitle: Text(model == 'Qwen3-0.6B' ? 'Default (litertlm)' : 'Coming soon'),
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
                  Text(tranche.displayName, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(tranche.trancheName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 16),
                  _detailSection('Product Details', {
                    'Product Type': tranche.product,
                    'Currency': '${tranche.currencyName} (${tranche.ccy})',
                    'Tenor': tranche.formattedTenor,
                    if (tranche.coupon != null) 'Coupon': '${tranche.coupon}%',
                    if (tranche.couponFreq != null) 'Coupon Frequency': tranche.couponFreq!,
                    if (tranche.principalProtection != null) 'Principal Protection': tranche.formattedProtection,
                    if (tranche.strike != null && tranche.strike != '0') 'Strike': '${tranche.strike}%',
                    if (tranche.ki != null && tranche.ki != '0') 'KI Barrier': '${tranche.ki}%',
                    if (tranche.ko != null && tranche.ko != '0') 'KO Barrier': '${tranche.ko}%',
                    if (tranche.prr != null) 'Risk Rating': 'PRR ${tranche.prr}',
                  }),
                  _detailSection('Subscription', {
                    'Subscription Period': tranche.formattedSubscriptionPeriod,
                    if (tranche.minOrder != null) 'Min Order': '${tranche.currencyName} ${tranche.formattedMinOrder}',
                    if (tranche.denomination != null) 'Denomination': tranche.denomination!,
                    if (tranche.eligibleSegments != null) 'Eligible Segments': tranche.eligibleSegments!,
                    if (tranche.eligibleCities != null) 'Eligible Cities': tranche.eligibleCities!,
                    if (tranche.issuer != null) 'Issuer': tranche.issuer!,
                    if (tranche.openToQI != null) 'Open to QI': tranche.openToQI!,
                  }),
                  if (tranche.underlyingName != null && tranche.underlyingName!.isNotEmpty)
                    _detailSection('Underlying', {
                      for (var i = 0; i < tranche.underlyingName!.length; i++)
                        tranche.underlyingName![i]: tranche.underlying != null && i < tranche.underlying!.length
                            ? tranche.underlying![i]
                            : '',
                    }),
                  if (tranche.minReturnPA != null || tranche.maxReturnPA != null)
                    _detailSection('Returns', {
                      if (tranche.minReturnPA != null) 'Min Return p.a.': tranche.minReturnPA!,
                      if (tranche.maxReturnPA != null) 'Max Return p.a.': tranche.maxReturnPA!,
                      if (tranche.barrierReturnPA != null) 'Barrier Return p.a.': tranche.barrierReturnPA!,
                      if (tranche.barrierPercent != null) 'Barrier Level': '${tranche.barrierPercent}%',
                      if (tranche.participationRate != null) 'Participation Rate': '${tranche.participationRate}%',
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
