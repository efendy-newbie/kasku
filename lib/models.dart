enum TxType { income, expense, transfer }

TxType txTypeFromString(String s) {
  switch (s) {
    case 'income':
      return TxType.income;
    case 'expense':
      return TxType.expense;
    default:
      return TxType.transfer;
  }
}

String txTypeToString(TxType t) {
  switch (t) {
    case TxType.income:
      return 'income';
    case TxType.expense:
      return 'expense';
    case TxType.transfer:
      return 'transfer';
  }
}

class Account {
  String id;
  String name;
  String type; // Tunai, E-Wallet, Bank, Tabungan, Investasi
  double balance;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'balance': balance,
      };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
        id: m['id'] as String,
        name: m['name'] as String,
        type: m['type'] as String,
        balance: (m['balance'] as num).toDouble(),
      );
}

class AppTransaction {
  String id;
  TxType type;
  double amount;
  String category; // empty string for transfers
  String note;
  String accountId;
  String? toAccountId; // only for transfer
  String date; // yyyy-MM-dd
  String time; // HH:mm

  AppTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.accountId,
    this.toAccountId,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': txTypeToString(type),
        'amount': amount,
        'category': category,
        'note': note,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'date': date,
        'time': time,
      };

  factory AppTransaction.fromMap(Map<String, dynamic> m) => AppTransaction(
        id: m['id'] as String,
        type: txTypeFromString(m['type'] as String),
        amount: (m['amount'] as num).toDouble(),
        category: (m['category'] ?? '') as String,
        note: (m['note'] ?? '') as String,
        accountId: m['accountId'] as String,
        toAccountId: m['toAccountId'] as String?,
        date: m['date'] as String,
        time: m['time'] as String,
      );
}

class Goal {
  String id;
  String name;
  double target;
  double current;
  String deadline; // yyyy-MM-dd or ''

  Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.current,
    required this.deadline,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'target': target,
        'current': current,
        'deadline': deadline,
      };

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
        id: m['id'] as String,
        name: m['name'] as String,
        target: (m['target'] as num).toDouble(),
        current: (m['current'] as num).toDouble(),
        deadline: (m['deadline'] ?? '') as String,
      );
}

class Budget {
  String category;
  double limit;

  Budget({required this.category, required this.limit});

  Map<String, dynamic> toMap() => {'category': category, 'limit': limit};

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
        category: m['category'] as String,
        limit: (m['limit'] as num).toDouble(),
      );
}

class CategoryDef {
  final String name;
  final String emoji;
  final int colorValue; // ARGB int

  const CategoryDef(this.name, this.emoji, this.colorValue);
}
