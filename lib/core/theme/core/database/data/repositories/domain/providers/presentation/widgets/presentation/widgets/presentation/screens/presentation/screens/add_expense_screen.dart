import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/expense_provider.dart';
import '../../core/theme/app_theme.dart';

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
    "Food": ["Groceries", "Restaurant", "Cafe", "Tea", "Coffee"],
    "Transportation": ["Fuel", "Metro", "Bus", "Taxi", "Uber"],
    "Medical": ["Medicine", "Doctor", "Hospital", "Gym"],
    "Unwarranted Expenses": ["Impulse Shopping", "Late Night Ordering", "Luxury Purchases", "Online Shopping", "Food Delivery", "Alcohol", "Cigarettes"]
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("New Entry", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "₹0.00",
                border: InputBorder.none,
                prefixStyle: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: "Category"),
              items: categories.keys.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) {
                setState(() {
                  selectedCategory = val!;
                  selectedSubcategory = categories[selectedCategory]!.first;
                  isUnwarranted = selectedCategory == "Unwarranted Expenses";
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSubcategory,
              decoration: const InputDecoration(labelText: "Subcategory"),
              items: categories[selectedCategory]!.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
              onChanged: (val) => setState(() => selectedSubcategory = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPaymentMethod,
              decoration: const InputDecoration(labelText: "Payment Method"),
              items: ["Cash", "UPI", "Credit Card", "Debit Card"]
                  .map((method) => DropdownMenuItem(value: method, child: Text(method))).toList(),
              onChanged: (val) => setState(() => selectedPaymentMethod = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Notes / Description"),
            ),
            const SizedBox(height: 32),
            if (isUnwarranted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warningOrange)
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warningOrange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Was this purchase really necessary?",
                        style: TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnwarranted ? AppColors.errorRed : AppColors.emeraldGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                onPressed: () async {
                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  if (amount > 0) {
                    await ref.read(transactionNotifierProvider.notifier).addTransaction(
                      amount: amount,
                      category: selectedCategory,
                      subcategory: selectedSubcategory,
                      paymentMethod: selectedPaymentMethod,
                      description: _descriptionController.text,
                      date: DateTime.now(),
                      isUnwarranted: isUnwarranted,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save Log", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
