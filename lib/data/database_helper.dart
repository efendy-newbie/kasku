import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kasku.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE accounts(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            balance REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions(
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT,
            note TEXT,
            accountId TEXT NOT NULL,
            toAccountId TEXT,
            date TEXT NOT NULL,
            time TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE goals(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            target REAL NOT NULL,
            current REAL NOT NULL,
            deadline TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE budgets(
            category TEXT PRIMARY KEY,
            budgetLimit REAL NOT NULL
          )
        ''');
      },
    );
  }

  // ---------------- Accounts ----------------
  Future<List<Account>> getAccounts() async {
    final db = await database;
    final rows = await db.query('accounts');
    return rows.map((r) => Account.fromMap(r)).toList();
  }

  Future<void> upsertAccount(Account a) async {
    final db = await database;
    await db.insert('accounts', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAccounts() async {
    final db = await database;
    await db.delete('accounts');
  }

  // ---------------- Transactions ----------------
  Future<List<AppTransaction>> getTransactions() async {
    final db = await database;
    final rows = await db.query('transactions');
    return rows.map((r) => AppTransaction.fromMap(r)).toList();
  }

  Future<void> upsertTransaction(AppTransaction t) async {
    final db = await database;
    await db.insert('transactions', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  // ---------------- Goals ----------------
  Future<List<Goal>> getGoals() async {
    final db = await database;
    final rows = await db.query('goals');
    return rows.map((r) => Goal.fromMap(r)).toList();
  }

  Future<void> upsertGoal(Goal g) async {
    final db = await database;
    await db.insert('goals', g.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearGoals() async {
    final db = await database;
    await db.delete('goals');
  }

  // ---------------- Budgets ----------------
  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final rows = await db.query('budgets');
    return rows
        .map((r) => Budget(
              category: r['category'] as String,
              limit: (r['budgetLimit'] as num).toDouble(),
            ))
        .toList();
  }

  Future<void> upsertBudget(Budget b) async {
    final db = await database;
    await db.insert(
      'budgets',
      {'category': b.category, 'budgetLimit': b.limit},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearBudgets() async {
    final db = await database;
    await db.delete('budgets');
  }

  Future<void> clearAll() async {
    await clearAccounts();
    await clearTransactions();
    await clearGoals();
    await clearBudgets();
  }
}
