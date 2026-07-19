import 'package:flutter/material.dart';
import '../models/tranche.dart';

class TrancheCard extends StatelessWidget {
  final Tranche tranche;
  final VoidCallback onTap;

  const TrancheCard({super.key, required this.tranche, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                tranche.currencyName,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                tranche.productCnName,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
              if (tranche.badges.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tranche.badges.map((b) => _buildBadge(b, cs)).toList(),
                ),
              ],
              const SizedBox(height: 14),
              _buildInfoRow('银行产品风险评级', _buildRiskRating(cs, theme)),
              const SizedBox(height: 8),
              _buildInfoRow('认购期', Text(tranche.formattedSubscriptionPeriod, style: _valueStyle)),
              const SizedBox(height: 8),
              _buildInfoRow('最低投资额', Text('${tranche.currencyName} ${tranche.formattedMinOrder}', style: _valueStyle)),
              const SizedBox(height: 8),
              _buildInfoRow('投资期限', Text(tranche.formattedTenor, style: _valueStyle)),
              const SizedBox(height: 8),
              _buildInfoRow('本金保障', Text(tranche.formattedProtection, style: _valueStyle)),
              if (tranche.underlyingDisplay.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  '挂钩标的',
                  Text(tranche.underlyingDisplay, style: _valueStyle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, ColorScheme cs) {
    final isWarning = label == '非保本';
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

  Widget _buildRiskRating(ColorScheme cs, ThemeData theme) {
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
