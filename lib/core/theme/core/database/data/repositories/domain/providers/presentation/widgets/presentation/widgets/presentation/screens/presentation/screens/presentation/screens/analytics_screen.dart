import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/expense_provider.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionNotifierProvider);
    final theme = Theme.of(context);

    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final unwarranted = transactions.where((t) => t.isUnwarranted).fold(0.0, (sum, t) => sum + t.amount);
    final savingsImpact = unwarranted * 12;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Deep Insights", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("AI Engine Metrics", style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Unwarranted Burn Rate", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text("₹${unwarranted.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.errorRed)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    "💡 Proactive Rule: You could save approximately ₹${savingsImpact.toStringAsFixed(2)} annually if this unnecessary spending behavior is suppressed.",
                    style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text("Behavioral Overview", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInsightTile(context, "Total Managed Capital", "₹${total.toStringAsFixed(2)}", Icons.account_balance_wallet_outlined),
            _buildInsightTile(context, "Impulse Leakage Ratio", total > 0 ? "${((unwarranted / total) * 100).toStringAsFixed(1)}%" : "0%", Icons.shutter_speed_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(BuildContext context, String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: Icon(icon, color: AppColors.emeraldGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
