import 'dart:math';

enum TransactionCategory {
  salary,
  bonus,
  investment,
  transferIn,
  dining,
  shopping,
  transport,
  entertainment,
  utilities,
  healthcare,
  education,
  travel,
  transferOut,
  other,
}

enum TransactionType { income, expense }

extension TransactionCategoryLabel on TransactionCategory {
  String label(bool isZh) {
    if (isZh) {
      switch (this) {
        case TransactionCategory.salary: return '工资';
        case TransactionCategory.bonus: return '奖金';
        case TransactionCategory.investment: return '投资收益';
        case TransactionCategory.transferIn: return '转入';
        case TransactionCategory.dining: return '餐饮';
        case TransactionCategory.shopping: return '购物';
        case TransactionCategory.transport: return '交通';
        case TransactionCategory.entertainment: return '娱乐';
        case TransactionCategory.utilities: return '生活缴费';
        case TransactionCategory.healthcare: return '医疗';
        case TransactionCategory.education: return '教育';
        case TransactionCategory.travel: return '旅行';
        case TransactionCategory.transferOut: return '转出';
        case TransactionCategory.other: return '其他';
      }
    }
    switch (this) {
      case TransactionCategory.salary: return 'Salary';
      case TransactionCategory.bonus: return 'Bonus';
      case TransactionCategory.investment: return 'Investment';
      case TransactionCategory.transferIn: return 'Transfer In';
      case TransactionCategory.dining: return 'Dining';
      case TransactionCategory.shopping: return 'Shopping';
      case TransactionCategory.transport: return 'Transport';
      case TransactionCategory.entertainment: return 'Entertainment';
      case TransactionCategory.utilities: return 'Utilities';
      case TransactionCategory.healthcare: return 'Healthcare';
      case TransactionCategory.education: return 'Education';
      case TransactionCategory.travel: return 'Travel';
      case TransactionCategory.transferOut: return 'Transfer Out';
      case TransactionCategory.other: return 'Other';
    }
  }
}

class DailyTransaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String? merchant;

  DailyTransaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    this.merchant,
  });

  String get formattedAmount {
    final prefix = type == TransactionType.income ? '+' : '-';
    final buf = StringBuffer(prefix);
    final s = amount.toInt().toString();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    if (amount != amount.truncateToDouble()) {
      buf.write('.${(amount - amount.truncate()).toStringAsFixed(2).substring(2)}');
    }
    return buf.toString();
  }

  String get categoryName {
    switch (category) {
      case TransactionCategory.salary:
        return '工资';
      case TransactionCategory.bonus:
        return '奖金';
      case TransactionCategory.investment:
        return '投资收益';
      case TransactionCategory.transferIn:
        return '转入';
      case TransactionCategory.dining:
        return '餐饮';
      case TransactionCategory.shopping:
        return '购物';
      case TransactionCategory.transport:
        return '交通';
      case TransactionCategory.entertainment:
        return '娱乐';
      case TransactionCategory.utilities:
        return '生活缴费';
      case TransactionCategory.healthcare:
        return '医疗';
      case TransactionCategory.education:
        return '教育';
      case TransactionCategory.travel:
        return '旅行';
      case TransactionCategory.transferOut:
        return '转出';
      case TransactionCategory.other:
        return '其他';
    }
  }

  String get categoryNameEn {
    switch (category) {
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.bonus:
        return 'Bonus';
      case TransactionCategory.investment:
        return 'Investment';
      case TransactionCategory.transferIn:
        return 'Transfer In';
      case TransactionCategory.dining:
        return 'Dining';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.healthcare:
        return 'Healthcare';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.travel:
        return 'Travel';
      case TransactionCategory.transferOut:
        return 'Transfer Out';
      case TransactionCategory.other:
        return 'Other';
    }
  }
}

class WeeklySummary {
  final double totalIncome;
  final double totalExpense;
  final Map<TransactionCategory, double> expenseByCategory;
  final Map<TransactionCategory, double> incomeByCategory;
  final List<DailyTransaction> transactions;

  WeeklySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.transactions,
  });

  double get netCashFlow => totalIncome - totalExpense;

  TransactionCategory? get topExpenseCategory {
    if (expenseByCategory.isEmpty) return null;
    return expenseByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<MapEntry<TransactionCategory, double>> get topExpenseCategories {
    final sorted = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }
}

class MockTransactionGenerator {
  static final MockTransactionGenerator instance = MockTransactionGenerator._();
  late final List<DailyTransaction> transactions;
  late final WeeklySummary weeklySummary;
  bool _initialized = false;

  MockTransactionGenerator._();

  void generate() {
    if (_initialized) return;
    _initialized = true;

    final random = Random(42);
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    transactions = [];

    _generateIncome(random, weekAgo, now);
    _generateExpenses(random, weekAgo, now);

    transactions.sort((a, b) => b.date.compareTo(a.date));

    _calculateSummary();
  }

  void _generateIncome(Random random, DateTime start, DateTime end) {
    final salaryDay = DateTime(start.year, start.month, 15);
    if (salaryDay.isAfter(start) && salaryDay.isBefore(end)) {
      transactions.add(DailyTransaction(
        id: 'INC001',
        date: salaryDay.add(Duration(hours: 9, minutes: random.nextInt(60))),
        description: 'Monthly Salary',
        amount: 35000 + random.nextDouble() * 5000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        merchant: 'ABC Corp',
      ));
    }

    final investmentDay = start.add(Duration(days: random.nextInt(3)));
    transactions.add(DailyTransaction(
      id: 'INC002',
      date: investmentDay.add(Duration(hours: 14, minutes: random.nextInt(120))),
      description: 'Fund Dividend',
      amount: 1200 + random.nextDouble() * 800,
      type: TransactionType.income,
      category: TransactionCategory.investment,
      merchant: 'ChinaAMC',
    ));

    if (random.nextBool()) {
      final transferDay = start.add(Duration(days: random.nextInt(5)));
      transactions.add(DailyTransaction(
        id: 'INC003',
        date: transferDay.add(Duration(hours: 10, minutes: random.nextInt(180))),
        description: 'Transfer from Li Ming',
        amount: 5000 + random.nextDouble() * 10000,
        type: TransactionType.income,
        category: TransactionCategory.transferIn,
        merchant: 'Li Ming',
      ));
    }
  }

  void _generateExpenses(Random random, DateTime start, DateTime end) {
    final diningMerchants = [
      '海底捞', '星巴克', '麦当劳', '西贝莜面村', '喜茶',
      '瑞幸咖啡', '必胜客', '肯德基', '美团外卖', '饿了么',
    ];
    final shoppingMerchants = [
      '淘宝', '京东', '拼多多', '天猫', '唯品会',
    ];
    final transportDescs = ['地铁充值', '滴滴出行', '出租车', '公交卡'];
    final entertainmentDescs = ['电影票', '视频会员', '游戏充值', 'KTV'];

    for (var day = 0; day < 7; day++) {
      final date = start.add(Duration(days: day));

      final diningCount = 1 + random.nextInt(3);
      for (var i = 0; i < diningCount; i++) {
        transactions.add(DailyTransaction(
          id: 'EXP_D${day}_$i',
          date: date.add(Duration(hours: 7 + random.nextInt(14), minutes: random.nextInt(60))),
          description: 'Dining',
          amount: 20 + random.nextDouble() * 200,
          type: TransactionType.expense,
          category: TransactionCategory.dining,
          merchant: diningMerchants[random.nextInt(diningMerchants.length)],
        ));
      }

      if (random.nextDouble() > 0.4) {
        transactions.add(DailyTransaction(
          id: 'EXP_S$day',
          date: date.add(Duration(hours: 10 + random.nextInt(10), minutes: random.nextInt(60))),
          description: 'Shopping',
          amount: 50 + random.nextDouble() * 2000,
          type: TransactionType.expense,
          category: TransactionCategory.shopping,
          merchant: shoppingMerchants[random.nextInt(shoppingMerchants.length)],
        ));
      }

      if (random.nextDouble() > 0.3) {
        transactions.add(DailyTransaction(
          id: 'EXP_T$day',
          date: date.add(Duration(hours: 8 + random.nextInt(12), minutes: random.nextInt(60))),
          description: transportDescs[random.nextInt(transportDescs.length)],
          amount: 5 + random.nextDouble() * 80,
          type: TransactionType.expense,
          category: TransactionCategory.transport,
        ));
      }

      if (random.nextDouble() > 0.6) {
        transactions.add(DailyTransaction(
          id: 'EXP_E$day',
          date: date.add(Duration(hours: 18 + random.nextInt(5), minutes: random.nextInt(60))),
          description: entertainmentDescs[random.nextInt(entertainmentDescs.length)],
          amount: 10 + random.nextDouble() * 200,
          type: TransactionType.expense,
          category: TransactionCategory.entertainment,
        ));
      }
    }

    if (random.nextBool()) {
      final utilityMerchants = ['电费', '水费', '燃气费', '手机话费', '宽带费'];
      transactions.add(DailyTransaction(
        id: 'EXP_UTIL',
        date: start.add(Duration(days: random.nextInt(3), hours: 10)),
        description: utilityMerchants[random.nextInt(utilityMerchants.length)],
        amount: 200 + random.nextDouble() * 500,
        type: TransactionType.expense,
        category: TransactionCategory.utilities,
        merchant: 'Utility Company',
      ));
    }

    if (random.nextDouble() > 0.5) {
      transactions.add(DailyTransaction(
        id: 'EXP_HC',
        date: start.add(Duration(days: random.nextInt(5), hours: 14)),
        description: 'Pharmacy',
        amount: 30 + random.nextDouble() * 300,
        type: TransactionType.expense,
        category: TransactionCategory.healthcare,
        merchant: 'Pharmacy',
      ));
    }
  }

  void _calculateSummary() {
    double totalIncome = 0;
    double totalExpense = 0;
    final expenseByCategory = <TransactionCategory, double>{};
    final incomeByCategory = <TransactionCategory, double>{};

    for (final txn in transactions) {
      if (txn.type == TransactionType.income) {
        totalIncome += txn.amount;
        incomeByCategory[txn.category] = (incomeByCategory[txn.category] ?? 0) + txn.amount;
      } else {
        totalExpense += txn.amount;
        expenseByCategory[txn.category] = (expenseByCategory[txn.category] ?? 0) + txn.amount;
      }
    }

    weeklySummary = WeeklySummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      expenseByCategory: expenseByCategory,
      incomeByCategory: incomeByCategory,
      transactions: transactions,
    );
  }
}
