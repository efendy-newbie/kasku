import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models.dart';
import '../utils/safety_score.dart';

const _uuid = Uuid();

class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late SharedPreferences _prefs;

  bool isReady = false;

  List<Account> accounts = [];
  List<AppTransaction> transactions = [];
  List<Goal> goals = [];
  List<Budget> budgets = [];
  List<CategoryDef> customExpenseCats = [];
  List<CategoryDef> customIncomeCats = [];

  ThemeMode themeMode = ThemeMode.system;
  String? pin;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    accounts = await _db.getAccounts();
    transactions = await _db.getTransactions();
    goals = await _db.getGoals();
    budgets = await _db.getBudgets();

    // First-ever launch: seed some friendly demo data so the app doesn't
    // look empty. Detected by absence of a "hasLaunched" flag.
    final hasLaunched = _prefs.getBool('hasLaunched') ?? false;
    if (!hasLaunched && accounts.isEmpty && transactions.isEmpty) {
      await _seedDemoData();
      accounts = await _db.getAccounts();
      transactions = await _db.getTransactions();
      goals = await _db.getGoals();
      budgets = await _db.getBudgets();
    }
    await _prefs.setBool('hasLaunched', true);

    final themeStr = _prefs.getString('theme') ?? 'system';
    themeMode = themeStr == 'light'
        ? ThemeMode.light
        : themeStr == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    pin = _prefs.getString('pin');

    customExpenseCats = _loadCustomCats('customExpenseCats');
    customIncomeCats = _loadCustomCats('customIncomeCats');

    isReady = true;
    notifyListeners();
  }

  List<CategoryDef> _loadCustomCats(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => CategoryDef(e['n'], e['i'], e['c'] as int))
        .toList();
  }

  Future<void> _saveCustomCats(String key, List<CategoryDef> list) async {
    final raw = jsonEncode(
        list.map((c) => {'n': c.name, 'i': c.emoji, 'c': c.colorValue}).toList());
    await _prefs.setString(key, raw);
  }

  Future<void> _seedDemoData() async {
    final acc = <Account>[
      Account(id: 'a_tunai', name: 'Tunai', type: 'Tunai', balance: 300000),
      Account(id: 'a_ovo', name: 'OVO', type: 'E-Wallet', balance: 450000),
      Account(id: 'a_gopay', name: 'GoPay', type: 'E-Wallet', balance: 200000),
      Account(id: 'a_dana', name: 'Dana', type: 'E-Wallet', balance: 150000),
      Account(id: 'a_shopee', name: 'ShopeePay', type: 'E-Wallet', balance: 50000),
      Account(id: 'a_bca', name: 'Bank BCA', type: 'Bank', balance: 2300000),
      Account(id: 'a_mandiri', name: 'Bank Mandiri', type: 'Bank', balance: 4100000),
    ];
    for (final a in acc) {
      await _db.upsertAccount(a);
    }

    String dOffset(int days) {
      final d = DateTime.now().subtract(Duration(days: days));
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    final demo = <AppTransaction>[
      AppTransaction(id: _uuid.v4(), type: TxType.income, amount: 2300000, category: 'Gaji', note: 'Gaji bulan ini', accountId: 'a_bca', date: dOffset(6), time: '09:00'),
      AppTransaction(id: _uuid.v4(), type: TxType.expense, amount: 45000, category: 'Makan', note: 'Makan siang', accountId: 'a_tunai', date: dOffset(0), time: '12:30'),
      AppTransaction(id: _uuid.v4(), type: TxType.expense, amount: 18000, category: 'Minum', note: 'Kopi', accountId: 'a_gopay', date: dOffset(0), time: '08:15'),
      AppTransaction(id: _uuid.v4(), type: TxType.expense, amount: 120000, category: 'Belanja', note: 'Belanja mingguan', accountId: 'a_dana', date: dOffset(1), time: '17:40'),
      AppTransaction(id: _uuid.v4(), type: TxType.expense, amount: 25000, category: 'Transport', note: 'Ojek online', accountId: 'a_gopay', date: dOffset(1), time: '07:50'),
      AppTransaction(id: _uuid.v4(), type: TxType.expense, amount: 150000, category: 'Internet', note: 'Wifi rumah', accountId: 'a_bca', date: dOffset(2), time: '10:00'),
      AppTransaction(id: _uuid.v4(), type: TxType.expense, amount: 60000, category: 'Hiburan', note: 'Nonton film', accountId: 'a_shopee', date: dOffset(3), time: '19:20'),
      AppTransaction(id: _uuid.v4(), type: TxType.income, amount: 350000, category: 'Freelance', note: 'Desain logo', accountId: 'a_dana', date: dOffset(4), time: '20:00'),
    ];
    for (final t in demo) {
      await _db.upsertTransaction(t);
    }

    await _db.upsertGoal(Goal(id: _uuid.v4(), name: 'Laptop Baru', target: 15000000, current: 4250000, deadline: ''));
    await _db.upsertBudget(Budget(category: 'Makan', limit: 800000));
    await _db.upsertBudget(Budget(category: 'Transport', limit: 300000));
    await _db.upsertBudget(Budget(category: 'Hiburan', limit: 250000));
  }

  // ---------------- Derived getters ----------------
  double get totalBalance => accounts.fold(0.0, (s, a) => s + a.balance);

  List<AppTransaction> transactionsForMonth(DateTime month) {
    return transactions.where((t) {
      final d = DateTime.parse(t.date);
      return d.year == month.year && d.month == month.month;
    }).toList();
  }

  double sumType(List<AppTransaction> list, TxType type) =>
      list.where((t) => t.type == type).fold(0.0, (s, t) => s + t.amount);

  SafetyScoreResult get safetyScore {
    final now = DateTime.now();
    final monthTx = transactionsForMonth(now);
    final income = sumType(monthTx, TxType.income);
    final expense = sumType(monthTx, TxType.expense);
    final daysWithTx = monthTx.map((t) => t.date).toSet().length;
    return computeSafetyScore(
      income: income,
      expense: expense,
      totalBalance: totalBalance,
      daysWithTx: daysWithTx,
      dayOfMonth: now.day,
    );
  }

  // ---------------- Mutations: Accounts ----------------
  Future<void> addAccount(Account a) async {
    accounts.add(a);
    await _db.upsertAccount(a);
    notifyListeners();
  }

  Future<void> updateAccount(Account a) async {
    final idx = accounts.indexWhere((x) => x.id == a.id);
    if (idx != -1) accounts[idx] = a;
    await _db.upsertAccount(a);
    notifyListeners();
  }

  Future<bool> deleteAccount(String id) async {
    final hasTx = transactions.any((t) => t.accountId == id || t.toAccountId == id);
    if (hasTx) return false;
    accounts.removeWhere((a) => a.id == id);
    await _db.deleteAccount(id);
    notifyListeners();
    return true;
  }

  void _adjustBalance(String accountId, double delta) {
    final idx = accounts.indexWhere((a) => a.id == accountId);
    if (idx == -1) return;
    accounts[idx].balance += delta;
    _db.upsertAccount(accounts[idx]);
  }

  // ---------------- Mutations: Transactions ----------------
  Future<void> addTransaction(AppTransaction t) async {
    transactions.add(t);
    await _db.upsertTransaction(t);
    _adjustBalance(t.accountId, t.type == TxType.income ? t.amount : -t.amount);
    notifyListeners();
  }

  Future<void> updateTransaction(AppTransaction updated) async {
    final idx = transactions.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    final old = transactions[idx];
    // revert old effect, then apply new
    _adjustBalance(old.accountId, old.type == TxType.income ? -old.amount : old.amount);
    transactions[idx] = updated;
    await _db.upsertTransaction(updated);
    _adjustBalance(updated.accountId, updated.type == TxType.income ? updated.amount : -updated.amount);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final idx = transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final t = transactions[idx];
    if (t.type == TxType.transfer) {
      _adjustBalance(t.accountId, t.amount);
      if (t.toAccountId != null) _adjustBalance(t.toAccountId!, -t.amount);
    } else {
      _adjustBalance(t.accountId, t.type == TxType.income ? -t.amount : t.amount);
    }
    transactions.removeAt(idx);
    await _db.deleteTransaction(id);
    notifyListeners();
  }

  Future<void> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String note,
  }) async {
    final t = AppTransaction(
      id: _uuid.v4(),
      type: TxType.transfer,
      amount: amount,
      category: '',
      note: note,
      accountId: fromAccountId,
      toAccountId: toAccountId,
      date: DateTime.now().toIso8601String().substring(0, 10),
      time: TimeOfDay.now().format24Hour(),
    );
    transactions.add(t);
    await _db.upsertTransaction(t);
    _adjustBalance(fromAccountId, -amount);
    _adjustBalance(toAccountId, amount);
    notifyListeners();
  }

  // ---------------- Mutations: Goals ----------------
  Future<void> addGoal(Goal g) async {
    goals.add(g);
    await _db.upsertGoal(g);
    notifyListeners();
  }

  Future<void> updateGoal(Goal g) async {
    final idx = goals.indexWhere((x) => x.id == g.id);
    if (idx != -1) goals[idx] = g;
    await _db.upsertGoal(g);
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    goals.removeWhere((g) => g.id == id);
    await _db.deleteGoal(id);
    notifyListeners();
  }

  Future<bool> fundGoal(String goalId, String fromAccountId, double amount) async {
    final acc = accounts.firstWhere((a) => a.id == fromAccountId);
    if (acc.balance < amount) return false;
    _adjustBalance(fromAccountId, -amount);
    final idx = goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return false;
    goals[idx].current += amount;
    await _db.upsertGoal(goals[idx]);
    notifyListeners();
    return true;
  }

  // ---------------- Mutations: Budgets ----------------
  Future<void> setBudget(String category, double limit) async {
    final idx = budgets.indexWhere((b) => b.category == category);
    if (idx != -1) {
      budgets[idx].limit = limit;
    } else {
      budgets.add(Budget(category: category, limit: limit));
    }
    await _db.upsertBudget(Budget(category: category, limit: limit));
    notifyListeners();
  }

  // ---------------- Custom categories ----------------
  Future<void> addCustomCategory(bool isIncome, CategoryDef cat) async {
    if (isIncome) {
      customIncomeCats.add(cat);
      await _saveCustomCats('customIncomeCats', customIncomeCats);
    } else {
      customExpenseCats.add(cat);
      await _saveCustomCats('customExpenseCats', customExpenseCats);
    }
    notifyListeners();
  }

  // ---------------- Settings ----------------
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final str = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _prefs.setString('theme', str);
    notifyListeners();
  }

  Future<void> setPin(String? newPin) async {
    pin = newPin;
    if (newPin == null) {
      await _prefs.remove('pin');
    } else {
      await _prefs.setString('pin', newPin);
    }
    notifyListeners();
  }

  // ---------------- Backup / Reset ----------------
  Map<String, dynamic> exportToJson() {
    return {
      'accounts': accounts.map((a) => a.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'goals': goals.map((g) => g.toMap()).toList(),
      'budgets': budgets.map((b) => b.toMap()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<bool> importFromJson(Map<String, dynamic> data) async {
    try {
      final newAccounts =
          (data['accounts'] as List).map((m) => Account.fromMap(m)).toList();
      final newTx = (data['transactions'] as List)
          .map((m) => AppTransaction.fromMap(m))
          .toList();
      final newGoals =
          (data['goals'] as List).map((m) => Goal.fromMap(m)).toList();
      final newBudgets =
          (data['budgets'] as List).map((m) => Budget.fromMap(m)).toList();

      await _db.clearAll();
      for (final a in newAccounts) {
        await _db.upsertAccount(a);
      }
      for (final t in newTx) {
        await _db.upsertTransaction(t);
      }
      for (final g in newGoals) {
        await _db.upsertGoal(g);
      }
      for (final b in newBudgets) {
        await _db.upsertBudget(b);
      }

      accounts = newAccounts;
      transactions = newTx;
      goals = newGoals;
      budgets = newBudgets;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetAllData() async {
    await _db.clearAll();
    accounts = [];
    transactions = [];
    goals = [];
    budgets = [];
    notifyListeners();
  }
}

extension on TimeOfDay {
  String format24Hour() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
