import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/transaction.dart';
import '../services/transaction_database.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final TransactionDatabase _db = TransactionDatabase.instance;
  List<Transaction> _transactions = [];
  Map<String, double> _portfolioSummary = {};
  bool _loading = true;
  String? _error;

  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final transactions = await _db.getAllTransactions();
      final summary = await _db.getPortfolioSummary();
      setState(() {
        _transactions = transactions;
        _portfolioSummary = summary;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Transaction> get _filteredTransactions {
    if (_statusFilter == null) return _transactions;
    return _transactions.where((t) => t.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
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
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildPortfolioSummary(l10n),
        _buildStatusFilter(l10n),
        Expanded(
          child: _filteredTransactions.isEmpty
              ? Center(
                  child: Text(
                    l10n.noTransactions,
                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 80),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(_filteredTransactions[index], l10n);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPortfolioSummary(AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    final activeCount = _transactions.where((t) => t.status == 'Active').length;
    final pendingCount = _transactions.where((t) => t.status == 'Pending').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.primaryContainer.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.portfolio, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryItem(l10n.activePositions, '$activeCount', cs),
              const SizedBox(width: 24),
              _summaryItem(l10n.pendingPositions, '$pendingCount', cs),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.totalInvestment, style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          ..._portfolioSummary.entries.map((e) => Text(
            '${e.key} ${_formatAmount(e.value)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
          )),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
        Text(label, style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildStatusFilter(AppStrings l10n) {
    final statuses = [null, 'Active', 'Pending', 'Matured', 'Cancelled'];
    final statusLabels = {
      null: l10n.filterAll,
      'Active': l10n.activePositions,
      'Pending': l10n.pendingPositions,
      'Matured': l10n.maturedPositions,
      'Cancelled': l10n.cancelledPositions,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statuses.map((status) {
                final isSelected = _statusFilter == status;
                final cs = Theme.of(context).colorScheme;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _statusFilter = status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? cs.primary : cs.outlineVariant,
                        ),
                      ),
                      child: Text(
                        statusLabels[status] ?? status ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.transactionCount(_filteredTransactions.length),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction txn, AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTransactionDetail(txn, l10n),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      txn.trancheName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(txn.status, cs),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(txn.transactionDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.category_outlined, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(txn.productType, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${txn.currency} ${txn.formattedAmount}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary),
                  ),
                  Text(
                    txn.tenor,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (txn.pnl != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      txn.pnl! >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: txn.pnl! >= 0 ? Colors.green[600] : Colors.red[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.pnl}: ${txn.pnl! >= 0 ? '+' : ''}${txn.currency} ${_formatAmount(txn.pnl!)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: txn.pnl! >= 0 ? Colors.green[600] : Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme cs) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'Active':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        break;
      case 'Pending':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        break;
      case 'Matured':
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        break;
      case 'Cancelled':
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[600]!;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  void _showTransactionDetail(Transaction txn, AppStrings l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
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
                  Text(txn.trancheName, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(txn.productType, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const SizedBox(height: 16),
                  _detailSection(l10n, {
                    l10n.status: txn.status,
                    l10n.transactionDate: txn.transactionDate,
                    '${l10n.amount} (${txn.currency})': txn.formattedAmount,
                    l10n.tenor: txn.tenor,
                    if (txn.coupon != null) l10n.detailLabel('Coupon'): '${txn.coupon}%',
                    if (txn.strike != null) l10n.detailLabel('Strike'): txn.strike!,
                    if (txn.underlyingAsset != null) l10n.underlyingAsset: txn.underlyingAsset!,
                    if (txn.settlementDate != null) l10n.settlementDate: txn.settlementDate!,
                    if (txn.maturityDate != null) l10n.maturity: txn.maturityDate!,
                    if (txn.pnl != null) l10n.pnl: '${txn.pnl! >= 0 ? '+' : ''}${txn.currency} ${_formatAmount(txn.pnl!)}',
                    if (txn.remarks.isNotEmpty) l10n.remarks: txn.remarks,
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailSection(AppStrings l10n, Map<String, String> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
}
