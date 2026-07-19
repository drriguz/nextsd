import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/daily_transaction.dart';

class DailyTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? initialParams;

  const DailyTransactionScreen({super.key, this.initialParams});

  @override
  State<DailyTransactionScreen> createState() => _DailyTransactionScreenState();
}

class _DailyTransactionScreenState extends State<DailyTransactionScreen> {
  TransactionType? _typeFilter;
  String? _periodFilter;
  double? _minAmount;
  double? _maxAmount;
  String? _categoryFilter;

  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialParams != null) {
      final p = widget.initialParams!;
      _periodFilter = p['period']?.toString();
      _typeFilter = _parseType(p['type']);
      _minAmount = (p['min_amount'] as num?)?.toDouble();
      _maxAmount = (p['max_amount'] as num?)?.toDouble();
      _categoryFilter = p['category']?.toString();
    }
  }

  TransactionType? _parseType(dynamic v) {
    if (v == 'income') return TransactionType.income;
    if (v == 'expense') return TransactionType.expense;
    return null;
  }

  List<DailyTransaction> get _filteredTransactions {
    var list = MockTransactionGenerator.instance.transactions;

    if (_periodFilter != null) {
      final now = DateTime.now();
      late DateTime start;
      switch (_periodFilter) {
        case 'last_week':
          start = now.subtract(const Duration(days: 7));
          break;
        case 'last_month':
          start = now.subtract(const Duration(days: 30));
          break;
        case 'this_month':
          start = DateTime(now.year, now.month, 1);
          break;
        default:
          start = DateTime(2000);
      }
      list = list.where((t) => t.date.isAfter(start)).toList();
    }

    if (_typeFilter != null) {
      list = list.where((t) => t.type == _typeFilter).toList();
    }

    if (_minAmount != null) {
      list = list.where((t) => t.amount >= _minAmount!).toList();
    }
    if (_maxAmount != null) {
      list = list.where((t) => t.amount <= _maxAmount!).toList();
    }

    if (_categoryFilter != null) {
      final q = _categoryFilter!.toLowerCase();
      list = list.where((t) {
        return t.categoryName.toLowerCase().contains(q) ||
            t.categoryNameEn.toLowerCase().contains(q) ||
            (t.merchant?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return list;
  }

  List<_DayGroup> get _groupedTransactions {
    final map = <DateTime, List<DailyTransaction>>{};
    for (final txn in _filteredTransactions) {
      final day = DateTime(txn.date.year, txn.date.month, txn.date.day);
      map.putIfAbsent(day, () => []).add(txn);
    }
    return map.entries
        .map((e) => _DayGroup(date: e.key, transactions: e.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactions),
      ),
      body: Column(
        children: [
          _buildFilterBar(l10n),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                _buildSummaryCard(l10n),
                ..._groupedTransactions.map((g) => _buildDayGroup(g, l10n)),
                if (_filteredTransactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(l10n.noTransactions,
                          style: TextStyle(color: Colors.grey[500])),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    final periods = {
      null: l10n.filterAll,
      'this_month': l10n.isZh ? '本月' : 'This Month',
      'last_week': l10n.isZh ? '上周' : 'Last Week',
      'last_month': l10n.isZh ? '上月' : 'Last Month',
    };

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period row
                Row(
                  children: periods.entries.map((e) {
                    final selected = e.key == _periodFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _filterChip(selected, e.value, cs,
                          () => setState(() => _periodFilter = e.key)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // Type + amount row
                Row(
                  children: [
                    _filterChip(_typeFilter == null, l10n.filterAll, cs,
                        () => setState(() => _typeFilter = null)),
                    const SizedBox(width: 8),
                    _filterChip(_typeFilter == TransactionType.income,
                        l10n.income, cs,
                        () =>
                            setState(() => _typeFilter = TransactionType.income)),
                    const SizedBox(width: 8),
                    _filterChip(_typeFilter == TransactionType.expense,
                        l10n.expense, cs,
                        () =>
                            setState(() => _typeFilter = TransactionType.expense)),
                    const Spacer(),
                    // Amount range
                    SizedBox(
                      width: 72,
                      height: 32,
                      child: TextField(
                        controller: _minController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: '¥Min',
                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          isDense: true,
                        ),
                        onSubmitted: (v) {
                          setState(() {
                            _minAmount =
                                v.isEmpty ? null : double.tryParse(v);
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('—', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ),
                    SizedBox(
                      width: 72,
                      height: 32,
                      child: TextField(
                        controller: _maxController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: '¥Max',
                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          isDense: true,
                        ),
                        onSubmitted: (v) {
                          setState(() {
                            _maxAmount =
                                v.isEmpty ? null : double.tryParse(v);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Active filter badge + count
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    l10n.transactionCount(_filteredTransactions.length),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _periodFilter = null;
                      _typeFilter = null;
                      _minAmount = null;
                      _maxAmount = null;
                      _categoryFilter = null;
                    }),
                    child: Text(l10n.clearFilter,
                        style: TextStyle(fontSize: 12, color: cs.primary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _periodFilter != null ||
      _typeFilter != null ||
      _minAmount != null ||
      _maxAmount != null ||
      _categoryFilter != null;

  Widget _filterChip(
      bool selected, String label, ColorScheme cs, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant)),
      ),
    );
  }

  Widget _buildSummaryCard(AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    final list = _filteredTransactions;
    final totalIncome =
        list.where((t) => t.type == TransactionType.income).fold<double>(0, (s, t) => s + t.amount);
    final totalExpense =
        list.where((t) => t.type == TransactionType.expense).fold<double>(0, (s, t) => s + t.amount);
    final net = totalIncome - totalExpense;

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
              child: _summaryStat(l10n.income, totalIncome, Colors.green, cs)),
          Container(width: 1, height: 36, color: Colors.grey[300]),
          Expanded(
              child: _summaryStat(l10n.expense, totalExpense, Colors.red, cs)),
          Container(width: 1, height: 36, color: Colors.grey[300]),
          Expanded(
              child: _summaryStat(l10n.weeklyNet, net,
                  net >= 0 ? Colors.green : Colors.red, cs)),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, double amount, Color color, ColorScheme cs) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text('¥${_fmt(amount)}',
            style:
                TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildDayGroup(_DayGroup group, AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    final dayTotal = group.transactions.fold<double>(
        0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Text(_formatDate(group.date, l10n),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${l10n.weeklyNet}: ¥${_fmt(dayTotal)}',
                style: TextStyle(
                    fontSize: 12,
                    color: dayTotal >= 0 ? Colors.green[600] : Colors.red[400]),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: group.transactions.map((txn) {
              final isIncome = txn.type == TransactionType.income;
              final color = isIncome ? Colors.green : Colors.red;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_categoryIcon(txn.category),
                          size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.isZh ? txn.categoryName : txn.categoryNameEn,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          if (txn.merchant != null)
                            Text(txn.merchant!,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'}¥${_fmt(txn.amount)}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                        Text(
                          '${txn.date.hour.toString().padLeft(2, '0')}:${txn.date.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
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

  IconData _categoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.salary: return Icons.work;
      case TransactionCategory.bonus: return Icons.card_giftcard;
      case TransactionCategory.investment: return Icons.trending_up;
      case TransactionCategory.transferIn: return Icons.call_received;
      case TransactionCategory.dining: return Icons.restaurant;
      case TransactionCategory.shopping: return Icons.shopping_bag;
      case TransactionCategory.transport: return Icons.directions_car;
      case TransactionCategory.entertainment: return Icons.movie;
      case TransactionCategory.utilities: return Icons.bolt;
      case TransactionCategory.healthcare: return Icons.local_hospital;
      case TransactionCategory.education: return Icons.school;
      case TransactionCategory.travel: return Icons.flight;
      case TransactionCategory.transferOut: return Icons.call_made;
      case TransactionCategory.other: return Icons.more_horiz;
    }
  }

  String _fmt(double amount) {
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

  String _formatDate(DateTime date, AppStrings l10n) {
    final months = l10n.isZh
        ? ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _DayGroup {
  final DateTime date;
  final List<DailyTransaction> transactions;
  _DayGroup({required this.date, required this.transactions});
}
