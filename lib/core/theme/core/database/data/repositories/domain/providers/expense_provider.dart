import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../data/repositories/expense_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final repositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(databaseProvider));
});

final transactionNotifierProvider = StateNotifierProvider<TransactionNotifier, List<LocalTransaction>>((ref) {
  return TransactionNotifier(ref.watch(repositoryProvider));
});

class TransactionNotifier extends StateNotifier<List<LocalTransaction>> {
  final ExpenseRepository _repository;
  TransactionNotifier(this._repository) : super([]) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = await _repository.getAllTransactions();
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
    final companion = LocalTransactionsCompanion(
      amount: Value(amount),
      category: Value(category),
      subcategory: Value(subcategory),
      paymentMethod: Value(paymentMethod),
      description: Value(description),
      date: Value(date),
      isUnwarranted: Value(isUnwarranted),
    );
    await _repository.insertTransaction(companion);
    await loadTransactions();
  }

  Future<void> removeTransaction(int id) async {
    await _repository.deleteTransaction(id);
    await loadTransactions();
  }
}
