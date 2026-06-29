import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

// --- LOCAL DATA OBJECT MODEL ---
class LocalTransaction {
  final int id;
  final double amount;
  final String category;
  final String subcategory;
  final String paymentMethod;
  final String description;
  final DateTime date;
  final bool isUnwarranted;

  LocalTransaction({
    required this.id, required this.amount, required this.category,
    required this.subcategory, required this.paymentMethod,
    required this.description, required this.date, required this.isUnwarranted
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'amount': amount, 'category': category, 'subcategory': subcategory,
    'paymentMethod': paymentMethod, 'description': description,
    'date': date.toIso8601String(), 'isUnwarranted': isUnwarranted
  };

  factory LocalTransaction.fromMap(Map<String, dynamic> map) => LocalTransaction(
    id: map['id'], amount: map['amount'], category: map['category'],
    subcategory: map['subcategory'], paymentMethod: map['paymentMethod'],
    description: map['description'] ?? '', date: DateTime.parse(map['date']),
    isUnwarranted: map['isUnwarranted'] ?? false
  );
}

// --- SECURE OFFLINE STORAGE ENGINE ---
class AppDatabase {
  Database? _database;
  final _store = intMapStoreFactory.store('transactions');

  Future<Database> get database async {
    if (_database != null) return _database!;
    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docDir.path, 'expenses_secure.db');
    _database = await databaseFactoryIo.openDatabase(dbPath);
    return _database!;
  }

  Future<List<LocalTransaction>> getAllTransactions() async {
    final db = await database;
    final snapshots = await _store.find(db);
    return snapshots.map((s) => LocalTransaction.fromMap(s.value)).toList();
  }

  Future<void> insertTransaction(double amount, String category, String subcategory, String method, String desc, DateTime date, bool unwarranted) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch;
    final tx = LocalTransaction(id: id, amount: amount, category: category, subcategory: subcategory, paymentMethod: method, description: desc, date: date, isUnwarranted: unwarranted);
    await _store.add(db, tx.toMap());
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    final finder = Finder(filter: Filter.equals('id', id));
    await _store.delete(db, finder: finder);
  }
}

// --- STATE ARCHITECTURE ENGINE ---
final dbProvider = Provider((ref) => AppDatabase());
final transactionNotifierProvider = StateNotifierProvider<TransactionNotifier, List<LocalTransaction>>((ref) => TransactionNotifier(ref.watch(dbProvider)));

class TransactionNotifier extends StateNotifier<List<LocalTransaction>> {
  final AppDatabase _db;
  TransactionNotifier(this._db) : super([]) { load(); }
  Future<void> load() async { state = await _db.getAllTransactions(); }
  Future<void> addTransaction({required double amount, required String category, required String subcategory, required String paymentMethod, required String description, required DateTime date, required bool isUnwarranted}) async {
    await _db.insertTransaction(amount, category, subcategory, paymentMethod, description, date, isUnwarranted);
    await load();
  }
  Future<void> removeTransaction(int id) async { await _db.deleteTransaction(id); await load(); }
}

// --- SYSTEM RUNNER & THEME ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

class AppColors {
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color bgDark = Color(0xFF111827);
  static const Color bgLight = Colors.white;
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color cardLight = Color(0xFFF3F4F6);
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light, scaffoldBackgroundColor: AppColors.bgLight, textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme), colorScheme: const ColorScheme.light(primary: AppColors.emeraldGreen, surface: AppColors.cardLight)),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: AppColors.bgDark, textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme), colorScheme: const ColorScheme.dark(primary: AppColors.emeraldGreen, surface: AppColors.cardDark)),
      home: const DashboardScreen(),
    );
  }
}

// --- PREMIUM USER INTERFACE ---
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionNotifierProvider);
    final theme = Theme.of(context);
    double total = transactions.fold(0.0, (sum, item) => sum + item.amount);
    double unwarranted = transactions.where((t) => t.isUnwarranted).fold(0.0, (sum, item) => sum + item.amount);

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
              Center(child: SizedBox(height: 180, child: PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 55, sections: [
                PieChartSectionData(color: AppColors.emeraldGreen, value: (total - unwarranted) <= 0 ? 1 : (total - unwarranted), radius: 20, title: ''),
                PieChartSectionData(color: AppColors.errorRed, value: unwarranted <= 0 ? 0 : unwarranted, radius: 24, title: ''),
              ])))),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Total Outflow", style: TextStyle(color: Colors.grey)), const SizedBox(height: 8), Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]))),
                  const SizedBox(width: 16),
                  Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: unwarranted > 0 ? AppColors.errorRed.withOpacity(0.1) : theme.colorScheme.surface, borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Unwarranted", style: TextStyle(color: unwarranted > 0 ? AppColors.errorRed : Colors.grey)), const SizedBox(height: 8), Text("₹${unwarranted.toStringAsFixed(2)}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: unwarranted > 0 ? AppColors.errorRed : null))]))),
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
                          elevation: 0,
                          color: theme.colorScheme.surface,
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
        backgroundColor: AppColors.emeraldGreen,
        foregroundColor: Colors.white,
      ),
    );
  }
}

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
  bool isUnwarranted = false;

  final Map<String, List<String>> categories = {
    "Food": ["Groceries", "Restaurant", "Cafe", "Tea", "Coffee"],
    "Transportation": ["Fuel", "Metro", "Bus", "Taxi", "Uber"],
    "Medical": ["Medicine", "Doctor", "Hospital", "Gym"],
    "Unwarranted Expenses": ["Impulse Shopping", "Late Night Ordering", "Luxury Purchases", "Online Shopping", "Food Delivery", "Alcohol"]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Entry", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _amountController, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold), decoration: const InputDecoration(hintText: "₹0.00", border: InputBorder.none)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(value: selectedCategory, decoration: const InputDecoration(labelText: "Category"), items: categories.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) {
              setState(() { selectedCategory = v!; selectedSubcategory = categories[selectedCategory]!.first; isUnwarranted = selectedCategory == "Unwarranted Expenses"; });
            }),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(value: selectedSubcategory, decoration: const InputDecoration(labelText: "Subcategory"), items: categories[selectedCategory]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => selectedSubcategory = v!)),
            const SizedBox(height: 32),
            if (isUnwarranted) ...[
              Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.warningOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.warningOrange)), child: const Text("⚠ Was this purchase really necessary?", style: TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.bold))),
              const SizedBox(height: 32),
            ],
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isUnwarranted ? AppColors.errorRed : AppColors.emeraldGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: () async {
              final amt = double.tryParse(_amountController.text) ?? 0.0;
              if (amt > 0) {
                await ref.read(transactionNotifierProvider.notifier).addTransaction(amount: amt, category: selectedCategory, subcategory: selectedSubcategory, paymentMethod: "UPI", description: _descriptionController.text, date: DateTime.now(), isUnwarranted: isUnwarranted);
                Navigator.pop(context);
              }
            }, child: const Text("Save Log", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionNotifierProvider);
    final unwarranted = transactions.where((t) => t.isUnwarranted).fold(0.0, (sum, t) => sum + t.amount);
    return Scaffold(
      appBar: AppBar(title: const Text("Deep Insights", style: TextStyle(fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Unwarranted Burn Rate", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Text("₹${unwarranted.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.errorRed)),
            const SizedBox(height: 24),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24)), child: Text("💡 Proactive Rule: Suppressing this leaking habit entirely saves you ₹${(unwarranted * 12).toStringAsFixed(2)} every year.", style: const TextStyle(height: 1.5, fontSize: 15, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }
}
