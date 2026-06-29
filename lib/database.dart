import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

class LocalTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get subcategory => text()();
  TextColumn get paymentMethod => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isUnwarranted => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [LocalTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;

  Future<List<LocalTransaction>> getAllTransactions() => select(localTransactions).get();
  
  Future<int> insertTransaction(double amount, String category, String subcategory, String paymentMethod, String? description, DateTime date, bool isUnwarranted) {
    return this.into(localTransactions).insert(LocalTransactionsCompanion(
      amount: Value(amount),
      category: Value(category),
      subcategory: Value(subcategory),
      paymentMethod: Value(paymentMethod),
      description: description != null ? Value(description) : const Value.absent(),
      date: Value(date),
      isUnwarranted: Value(isUnwarranted),
    ));
  }

  Future<bool> deleteTransaction(int id) async {
    return (delete(localTransactions)..where((t) => t.id.equals(id))).go() > 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'expenses.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
