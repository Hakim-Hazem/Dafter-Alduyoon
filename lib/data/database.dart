import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/debt.dart';
import '../models/payment.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'dayni_debts.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''CREATE TABLE debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT, person TEXT NOT NULL,
        amount REAL NOT NULL, currency TEXT NOT NULL, created_at TEXT NOT NULL,
        due_date TEXT, note TEXT NOT NULL DEFAULT '', paid REAL NOT NULL DEFAULT 0
      )''');
      await db.execute('''CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT, debt_id INTEGER NOT NULL,
        amount REAL NOT NULL, paid_at TEXT NOT NULL, note TEXT NOT NULL DEFAULT '',
        FOREIGN KEY(debt_id) REFERENCES debts(id) ON DELETE CASCADE
      )''');
    });
    return _db!;
  }

  Future<List<Debt>> allDebts() async {
    final db = await database;
    final rows = await db.query('debts', orderBy: 'created_at DESC');
    return rows.map(Debt.fromMap).toList();
  }

  Future<int> saveDebt(Debt debt) async {
    final db = await database;
    if (debt.id == null) return db.insert('debts', debt.toMap()..remove('id'));
    await db.update('debts', debt.toMap()..remove('id'), where: 'id=?', whereArgs: [debt.id]);
    return debt.id!;
  }

  Future<void> deleteDebt(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments', where: 'debt_id=?', whereArgs: [id]);
      await txn.delete('debts', where: 'id=?', whereArgs: [id]);
    });
  }

  Future<void> addPayment(Payment payment, double newPaid) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('payments', payment.toMap()..remove('id'));
      await txn.update('debts', {'paid': newPaid}, where: 'id=?', whereArgs: [payment.debtId]);
    });
  }

  Future<List<Payment>> paymentsFor(int debtId) async {
    final db = await database;
    final rows = await db.query('payments', where: 'debt_id=?', whereArgs: [debtId], orderBy: 'paid_at DESC');
    return rows.map(Payment.fromMap).toList();
  }
}
