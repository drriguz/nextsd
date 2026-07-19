import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/tranche.dart';

class TrancheCard extends StatelessWidget {
  final Tranche tranche;
  final VoidCallback onTap;

  const TrancheCard({super.key, required this.tranche, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = AppStrings.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tranche.trancheName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.currencyName(tranche.ccy),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                l.productTypeName(tranche.productNameCN, tranche.product),
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
              if (_badges(l).isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _badges(l).map((b) => _buildBadge(b, cs, l)).toList(),
                ),
              ],
              const SizedBox(height: 14),
              _buildInfoRow(l.riskRating, _buildRiskRating(cs)),
              const SizedBox(height: 8),
              _buildInfoRow(l.subscriptionPeriod, Text(l.formatSubscriptionPeriod(tranche.windowPeriodStartDate, tranche.windowPeriodEndDate), style: _valueStyle)),
              const SizedBox(height: 8),
              _buildInfoRow(l.minInvestment, Text('${l.currencyName(tranche.ccy)} ${tranche.formattedMinOrder}', style: _valueStyle)),
              const SizedBox(height: 8),
              _buildInfoRow(l.investmentTenor, Text(l.formatTenor(tranche.tenor), style: _valueStyle)),
              const SizedBox(height: 8),
              _buildInfoRow(l.principalProtection, Text(tranche.formattedProtection, style: _valueStyle)),
              if (tranche.underlyingDisplay.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(l.underlyingAsset, Text(tranche.underlyingDisplay, style: _valueStyle)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<String> _badges(AppStrings l) {
    final result = <String>[];
    if (!tranche.isPrincipalProtected) result.add(l.nonProtected);
    if (tranche.isQIOnly) result.add(l.qualifiedInvestor);
    return result;
  }

  Widget _buildBadge(String label, ColorScheme cs, AppStrings l) {
    final isWarning = label == l.nonProtected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(
          color: isWarning ? cs.error.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isWarning ? cs.error : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildRiskRating(ColorScheme cs) {
    final rating = int.tryParse(tranche.prr ?? '') ?? 0;
    final colors = [
      Colors.transparent,
      const Color(0xFF4CAF50),
      const Color(0xFF8BC34A),
      const Color(0xFFFFC107),
      const Color(0xFFFF9800),
      const Color(0xFFFF5722),
      const Color(0xFFD32F2F),
    ];
    final color = rating > 0 && rating < colors.length ? colors[rating] : cs.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(rating > 0 ? rating : 1, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Icon(Icons.square_rounded, size: 12, color: i < rating ? color : Colors.grey[300]),
          );
        }),
        const SizedBox(width: 4),
        Text('$rating', style: _valueStyle.copyWith(fontSize: 14)),
      ],
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ),
        Expanded(child: value),
      ],
    );
  }

  static const _valueStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
}
