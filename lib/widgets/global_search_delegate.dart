import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/tranche.dart';
import '../models/transaction.dart';
import '../services/transaction_database.dart';
import '../screens/tranche_detail_screen.dart';

class GlobalSearchDelegate extends SearchDelegate {
  final List<Tranche> tranches;
  final AppStrings l10n;

  GlobalSearchDelegate({required this.tranches, required this.l10n});

  @override
  String get searchFieldLabel => l10n.searchHint;

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
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(l10n.searchHint, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    final lowerQuery = query.toLowerCase();

    final matchedTranches = tranches.where((t) {
      return t.trancheName.toLowerCase().contains(lowerQuery) ||
          t.product.toLowerCase().contains(lowerQuery) ||
          (t.productNameCN?.toLowerCase().contains(lowerQuery) ?? false) ||
          t.ccy.toLowerCase().contains(lowerQuery) ||
          (t.underlying?.any((u) => u.toLowerCase().contains(lowerQuery)) ?? false) ||
          (t.underlyingName?.any((u) => u.toLowerCase().contains(lowerQuery)) ?? false) ||
          (t.issuer?.toLowerCase().contains(lowerQuery) ?? false) ||
          (t.eligibleSegments?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    return FutureBuilder<List<Transaction>>(
      future: TransactionDatabase.instance.getAllTransactions(),
      builder: (context, snapshot) {
        final allTransactions = snapshot.data ?? [];
        final matchedTransactions = allTransactions.where((t) {
          return t.trancheName.toLowerCase().contains(lowerQuery) ||
              t.productType.toLowerCase().contains(lowerQuery) ||
              t.currency.toLowerCase().contains(lowerQuery) ||
              t.status.toLowerCase().contains(lowerQuery) ||
              (t.underlyingAsset?.toLowerCase().contains(lowerQuery) ?? false) ||
              t.remarks.toLowerCase().contains(lowerQuery);
        }).toList();

        if (matchedTranches.isEmpty && matchedTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(l10n.noResults, style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (matchedTranches.isNotEmpty) ...[
              _sectionHeader(l10n.searchProducts, matchedTranches.length, context),
              ...matchedTranches.map((t) => _buildTrancheTile(t, context)),
            ],
            if (matchedTransactions.isNotEmpty) ...[
              _sectionHeader(l10n.searchTransactions, matchedTransactions.length, context),
              ...matchedTransactions.map((t) => _buildTransactionTile(t, context)),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String label, int count, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onPrimaryContainer)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrancheTile(Tranche tranche, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Icon(Icons.account_balance, size: 18, color: cs.onPrimaryContainer),
      ),
      title: Text(tranche.trancheName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${tranche.product} · ${tranche.ccy} · ${tranche.tenor}', style: TextStyle(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: () {
        close(context, null);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TrancheDetailScreen(tranche: tranche)),
        );
      },
    );
  }

  Widget _buildTransactionTile(Transaction txn, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color statusColor;
    switch (txn.status) {
      case 'Active':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Matured':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.tertiaryContainer,
        child: Icon(Icons.receipt_long, size: 18, color: cs.onTertiaryContainer),
      ),
      title: Text(txn.trancheName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Text('${txn.productType} · ${txn.currency} ${txn.formattedAmount}', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(txn.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: () {
        close(context, null);
      },
    );
  }
}
