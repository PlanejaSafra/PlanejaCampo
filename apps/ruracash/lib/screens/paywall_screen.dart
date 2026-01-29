import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/premium_service.dart';

/// CASH-30: Paywall screen shown when accessing premium features.
class PaywallScreen extends StatelessWidget {
  final PremiumFeature? feature;

  const PaywallScreen({super.key, this.feature});

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cashPaywallTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              l10n.cashPaywallHeadline,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Feature list
            ...[
              _FeatureRow(icon: Icons.account_balance, text: l10n.cashPaywallFeatureContas),
              _FeatureRow(icon: Icons.attach_money, text: l10n.cashPaywallFeatureReceitas),
              _FeatureRow(icon: Icons.swap_horiz, text: l10n.cashPaywallFeatureTransferencias),
              _FeatureRow(icon: Icons.receipt_long, text: l10n.cashPaywallFeatureContasPagar),
              _FeatureRow(icon: Icons.pie_chart, text: l10n.cashPaywallFeatureOrcamento),
              _FeatureRow(icon: Icons.analytics, text: l10n.cashPaywallFeatureRelatorios),
              _FeatureRow(icon: Icons.compare_arrows, text: l10n.cashPaywallFeatureReconciliacao),
              _FeatureRow(icon: Icons.category, text: l10n.cashPaywallFeatureCategorias),
            ],
            const SizedBox(height: 32),

            // Yearly plan (recommended)
            _PlanCard(
              title: l10n.cashPaywallPlanYearly,
              price: l10n.cashPaywallPriceYearly,
              subtitle: l10n.cashPaywallSavings,
              isRecommended: true,
              onTap: () => _purchase(context, PremiumPlan.yearly),
            ),
            const SizedBox(height: 12),

            // Monthly plan
            _PlanCard(
              title: l10n.cashPaywallPlanMonthly,
              price: l10n.cashPaywallPriceMonthly,
              isRecommended: false,
              onTap: () => _purchase(context, PremiumPlan.monthly),
            ),
            const SizedBox(height: 16),

            // Restore
            TextButton(
              onPressed: () => _restore(context),
              child: Text(l10n.cashPaywallRestore),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(BuildContext context, PremiumPlan plan) async {
    final l10n = CashLocalizations.of(context)!;
    final result = await PremiumService.instance.purchase(plan);
    if (context.mounted) {
      if (result) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cashPaywallPurchaseUnavailable)),
        );
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    final l10n = CashLocalizations.of(context)!;
    final result = await PremiumService.instance.restore();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? l10n.cashPaywallRestoreSuccess : l10n.cashPaywallRestoreEmpty),
        ),
      );
      if (result) Navigator.pop(context, true);
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String? subtitle;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    this.subtitle,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isRecommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecommended
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('MELHOR VALOR',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (subtitle != null)
                      Text(subtitle!, style: const TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                ),
              ),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
