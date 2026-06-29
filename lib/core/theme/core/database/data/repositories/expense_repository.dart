import '../../core/database/app_database.dart';

class ExpenseRepository {
  final AppDatabase _db;
  ExpenseRepository(this._db);

  Future<List<LocalTransaction>> getAllTransactions() async {
    return await _db.select(_db.localTransactions).get();
  }

  Future<int> insertTransaction(LocalTransactionsCompanion entity) async {
    return await _db.into(_db.localTransactions).insert(entity);
  }

  Future<bool> deleteTransaction(int id) async {
    return (await _db.delete(_db.localTransactions)..where((t) => t.id.equals(id))).go() > 0;
  }
}
