import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database.dart'; // Links to our clean database file

// --- THEME ---
class AppColors {
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color bgDark = Color(0xFF111827);
  static const Color bgLight = Colors.white;
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color cardLight = Color(0xFFF3F4F6);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: const ColorScheme.light(primary: AppColors.emeraldGreen, surface: AppColors.cardLight),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
  );
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(primary: AppColors.emeraldGreen, surface: AppColors.cardDark),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
  );
}

// --- STATE PROVIDERS ---
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final transactionNotifierProvider = StateNotifierProvider<TransactionNotifier, List<LocalTransaction>>((ref) {
  return TransactionNotifier(ref.watch(databaseProvider));
});

class TransactionNotifier extends StateNotifier<List<LocalTransaction>> {
  final AppDatabase _db;
  TransactionNotifier(this._db) : super([]) { loadTransactions(); }

  Future<void> loadTransactions() async {
    state = await _db.getAllTransactions();
  }

  Future<void> addTransaction({
    required double amount,
    required String category,
    required String subcategory,
    required String paymentMethod,
    required String description,
    required DateTime date,
    required bool isUnwarranted,
  }) async {
    await _db.insertTransaction(amount, category, subcategory, paymentMethod, description, date, isUnwarranted);
    await loadTransactions();
  }

  Future<void> removeTransaction(int id) async {
    await _db.deleteTransaction(id);
    await loadTransactions();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}

// --- DASHBOARD SCREEN ---
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
          padding: const EdgeInsets.all(24.0),
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
                      const Text("Clean financial footprint", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.analytics_outlined, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
                ],
              ),
              const SizedBox(height: 32),
              Center(child: SizedBox(height: 180, child: PremiumCircularChart(totalSpending: totalSpending, unwarrantedSpending: unwarrantedSpending))),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: MetricCard(title: "Total Outflow", value: "₹${totalSpending.toStringAsFixed(2)}", isAlert: false)),
                  const SizedBox(width: 16),
                  Expanded(child: MetricCard(title: "Unwarranted", value: "₹${unwarrantedSpending.toStringAsFixed(2)}", isAlert: unwarrantedSpending > 0)),
                ],
              ),
              const SizedBox(height: 32),
              const Text("Recent Records", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              transactions.isEmpty 
                ? const Center(child: Text("No entries recorded yet."))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[transactions.length - 1 - index];
                      return Dismissible(
                        key: Key(tx.id.toString()),
                        onDismissed: (_) => ref.read(transactionNotifierProvider.notifier).removeTransaction(tx.id),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(tx.subcategory),
                            trailing: Text("₹${tx.amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: tx.isUnwarranted ? AppColors.errorRed : null)),
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
      ),
    );
  }
}

// --- ADD EXPENSE SCREEN ---
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String selectedCategory = "Food";
  String selectedSubcategory = "Groceries";
  String selectedPaymentMethod = "UPI";
  bool isUnwarranted = false;

  final Map<String, List<String>> categories = {
    "Food": ["Groceries", "Restaurant", "Cafe"],
    "Transportation": ["Fuel", "Metro", "Uber"],
    "Unwarranted Expenses": ["Impulse Shopping", "Late Night Ordering", "Alcohol"]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Entry")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _amountController, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold), decoration: const InputDecoration(hintText: "₹0.00")),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(value: selectedCategory, items: categories.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) {
              setState(() { selectedCategory = v!; selectedSubcategory = categories[selectedCategory]!.first; isUnwarranted = selectedCategory == "Unwarranted Expenses"; });
            }),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(value: selectedSubcategory, items: categories[selectedCategory]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => selectedSubcategory = v!)),
            const SizedBox(height: 32),
            if (isUnwarranted) ...[
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.warningOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: const Text("⚠ Was this purchase really necessary?", style: TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.bold))),
              const SizedBox(height: 32),
            ],
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: () async {
              final amt = double.tryParse(_amountController.text) ?? 0.0;
              if (amt > 0) {
                await ref.read(transactionNotifierProvider.notifier).addTransaction(amount: amt, category: selectedCategory, subcategory: selectedSubcategory, paymentMethod: selectedPaymentMethod, description: _descriptionController.text, date: DateTime.now(), isUnwarranted: isUnwarranted);
                Navigator.pop(context);
              }
            }, child: const Text("Save Log"))),
          ],
        ),
      ),
    );
  }
}

// --- ANALYTICS SCREEN ---
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionNotifierProvider);
    final unwarranted = transactions.where((t) => t.isUnwarranted).fold(0.0, (sum, t) => sum + t.amount);
    return Scaffold(
      appBar: AppBar(title: const Text("Deep Insights")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Unwarranted Burn Rate", style: TextStyle(color: Colors.grey)),
            Text("₹${unwarranted.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.errorRed)),
            const SizedBox(height: 16),
            Text("💡 Proactive Rule: Suppressing this leak completely saves you ₹${(unwarranted * 12).toStringAsFixed(2)} annually.", style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// --- METRIC CARD WIDGET ---
class MetricCard extends StatelessWidget {
  final String title; final String value; final bool isAlert;
  const MetricCard({required this.title, required this.value, required this.isAlert});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isAlert ? AppColors.errorRed.withOpacity(0.1) : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: isAlert ? AppColors.errorRed : Colors.grey)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
    );
  }
}

// --- CIRCULAR CHART WIDGET ---
class PremiumCircularChart extends StatelessWidget {
  final double totalSpending; final double unwarrantedSpending;
  const PremiumCircularChart({required this.totalSpending, required this.unwarrantedSpending});
  @override
  Widget build(BuildContext context) {
    return PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 55, sections: [
      PieChartSectionData(color: AppColors.emeraldGreen, value: (totalSpending - unwarrantedSpending) <= 0 ? 1 : (totalSpending - unwarrantedSpending), radius: 20, title: ''),
      PieChartSectionData(color: AppColors.errorRed, value: unwarrantedSpending, radius: 24, title: ''),
    ]));
  }
}
