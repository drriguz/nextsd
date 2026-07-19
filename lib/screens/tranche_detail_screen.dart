import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/tranche.dart';
import 'product_chat_screen.dart';

class TrancheDetailScreen extends StatelessWidget {
  final Tranche tranche;
  final String locale;

  const TrancheDetailScreen({
    super.key,
    required this.tranche,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productTypeName(tranche.productNameCN, tranche.product)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductChatScreen(tranche: tranche, locale: locale),
            ),
          );
        },
        icon: const Icon(Icons.chat_outlined),
        label: Text(l10n.isZh ? 'AI 顾问' : 'AI Advisor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
