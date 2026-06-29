import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/expense_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/circular_chart.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionNotifierProvider);
    final theme = Theme.of(context);

    double totalSpending = transactions.fold(0.0, (sum, item) => sum + item.amount);
    double unwarrantedSpending = transactions.where((t) => t.isUnwarranted).fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Overview", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text("Clean financial footprint", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  height: 200,
                  child: PremiumCircularChart(totalSpending: totalSpending, unwarrantedSpending: unwarrantedSpending),
                ),
              ),
              const SizedBox(height: 32),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  MetricCard(title: "Total Outflow", value: "₹${totalSpending.toStringAsFixed(2)}", isAlert: false),
                  MetricCard(title: "Unwarranted", value: "₹${unwarrantedSpending.toStringAsFixed(2)}", isAlert: unwarrantedSpending > 0),
                ],
              ),
              const SizedBox(height: 32),
              Text("Recent Records", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              transactions.isEmpty 
                ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("No transactions recorded yet.")))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length > 5 ? 5 : transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[transactions.length - 1 - index];
                      return Dismissible(
                        key: Key(tx.id.toString()),
                        background: Container(
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.right(20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => ref.read(transactionNotifierProvider.notifier).removeTransaction(tx.id),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: theme.colorScheme.surface,
                          child: ListTile(
                            title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(tx.subcategory),
                            trailing: Text(
                              "₹${tx.amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx.isUnwarranted ? theme.colorScheme.error : theme.textTheme.bodyLarge?.color
                              )
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        label: const Text("Add Record"),
        icon: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }
}
