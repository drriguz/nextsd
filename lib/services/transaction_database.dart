import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';

class TransactionDatabase {
  static final TransactionDatabase instance = TransactionDatabase._init();
  static Database? _database;

  TransactionDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_date TEXT NOT NULL,
        product_type TEXT NOT NULL,
        tranche_name TEXT NOT NULL,
        currency TEXT NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        tenor TEXT NOT NULL,
        coupon REAL,
        strike TEXT,
        underlying_asset TEXT,
        settlement_date TEXT,
        maturity_date TEXT,
        pnl REAL,
        remarks TEXT
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final transactions = [
      Transaction(
        transactionDate: '2025-01-15',
        productType: 'WoB Autocall',
        trancheName: 'AAPL+MSFT Autocall 2025-01',
        currency: 'CNY',
        amount: 1000000,
        status: 'Active',
        tenor: '12M',
        coupon: 8.5,
        strike: '80%',
        underlyingAsset: 'AAPL, MSFT',
        settlementDate: '2025-01-17',
        maturityDate: '2026-01-17',
        remarks: 'Monthly observation, autocall at 103%',
      ),
      Transaction(
        transactionDate: '2025-02-20',
        productType: 'Snowball',
        trancheName: 'HSI Snowball 2025-02',
        currency: 'HKD',
        amount: 2000000,
        status: 'Active',
        tenor: '24M',
        coupon: 12.0,
        strike: '75%',
        underlyingAsset: 'HSI',
        settlementDate: '2025-02-22',
        maturityDate: '2027-02-22',
        remarks: 'Quarterly knock-out observation',
      ),
      Transaction(
        transactionDate: '2024-11-05',
        productType: 'Range Accrual',
        trancheName: 'EUR/USD Range Accrual 2024-11',
        currency: 'USD',
        amount: 500000,
        status: 'Matured',
        tenor: '6M',
        coupon: 6.2,
        strike: 'N/A',
        underlyingAsset: 'EUR/USD',
        settlementDate: '2024-11-07',
        maturityDate: '2025-05-07',
        pnl: 15500,
        remarks: 'Daily accrual within range [1.05, 1.15]',
      ),
      Transaction(
        transactionDate: '2025-03-10',
        productType: 'Averaging Autocall',
        trancheName: 'TSLA Avg Autocall 2025-03',
        currency: 'USD',
        amount: 800000,
        status: 'Active',
        tenor: '18M',
        coupon: 10.5,
        strike: '70%',
        underlyingAsset: 'TSLA',
        settlementDate: '2025-03-12',
        maturityDate: '2026-09-12',
        remarks: 'Monthly averaging, quarterly autocall',
      ),
      Transaction(
        transactionDate: '2024-08-22',
        productType: 'WoB Autocall',
        trancheName: 'BABA+JD Autocall 2024-08',
        currency: 'CNY',
        amount: 1500000,
        status: 'Matured',
        tenor: '6M',
        coupon: 7.8,
        strike: '85%',
        underlyingAsset: 'BABA, JD',
        settlementDate: '2024-08-24',
        maturityDate: '2025-02-24',
        pnl: 58500,
        remarks: 'Autocalled at month 3',
      ),
      Transaction(
        transactionDate: '2025-04-01',
        productType: 'Snowball',
        trancheName: 'CSI300 Snowball 2025-04',
        currency: 'CNY',
        amount: 3000000,
        status: 'Active',
        tenor: '24M',
        coupon: 15.0,
        strike: '80%',
        underlyingAsset: 'CSI300',
        settlementDate: '2025-04-03',
        maturityDate: '2027-04-03',
        remarks: 'Monthly observation, knock-in at 70%',
      ),
      Transaction(
        transactionDate: '2025-01-28',
        productType: 'Range Accrual',
        trancheName: 'USD/JPY Range Accrual 2025-01',
        currency: 'USD',
        amount: 600000,
        status: 'Active',
        tenor: '12M',
        coupon: 5.8,
        strike: 'N/A',
        underlyingAsset: 'USD/JPY',
        settlementDate: '2025-01-30',
        maturityDate: '2026-01-30',
        remarks: 'Daily accrual within range [140, 160]',
      ),
      Transaction(
        transactionDate: '2024-12-15',
        productType: 'Averaging Autocall',
        trancheName: 'NVDA Avg Autocall 2024-12',
        currency: 'USD',
        amount: 1200000,
        status: 'Active',
        tenor: '12M',
        coupon: 9.0,
        strike: '75%',
        underlyingAsset: 'NVDA',
        settlementDate: '2024-12-17',
        maturityDate: '2025-12-17',
        remarks: 'Monthly averaging, quarterly autocall',
      ),
      Transaction(
        transactionDate: '2024-06-10',
        productType: 'WoB Autocall',
        trancheName: 'KWEB+FXI Autocall 2024-06',
        currency: 'CNY',
        amount: 800000,
        status: 'Cancelled',
        tenor: '12M',
        coupon: 0,
        strike: '80%',
        underlyingAsset: 'KWEB, FXI',
        remarks: 'Cancelled before settlement',
      ),
      Transaction(
        transactionDate: '2025-05-12',
        productType: 'Snowball',
        trancheName: 'HSCEI Snowball 2025-05',
        currency: 'HKD',
        amount: 2500000,
        status: 'Pending',
        tenor: '24M',
        coupon: 14.0,
        strike: '78%',
        underlyingAsset: 'HSCEI',
        remarks: 'Awaiting settlement confirmation',
      ),
      Transaction(
        transactionDate: '2024-09-05',
        productType: 'Range Accrual',
        trancheName: 'GBP/USD Range Accrual 2024-09',
        currency: 'USD',
        amount: 450000,
        status: 'Matured',
        tenor: '6M',
        coupon: 5.5,
        strike: 'N/A',
        underlyingAsset: 'GBP/USD',
        settlementDate: '2024-09-07',
        maturityDate: '2025-03-07',
        pnl: 12375,
        remarks: 'Daily accrual within range [1.20, 1.35]',
      ),
      Transaction(
        transactionDate: '2025-06-20',
        productType: 'WoB Autocall',
        trancheName: 'GOOG+AMZN Autocall 2025-06',
        currency: 'USD',
        amount: 1800000,
        status: 'Active',
        tenor: '12M',
        coupon: 7.5,
        strike: '82%',
        underlyingAsset: 'GOOG, AMZN',
        settlementDate: '2025-06-22',
        maturityDate: '2026-06-22',
        remarks: 'Monthly observation, autocall at 100%',
      ),
    ];

    for (final txn in transactions) {
      await db.insert('transactions', txn.toMap());
    }
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final result = await db.query('transactions', orderBy: 'transaction_date DESC');
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getTransactionsByStatus(String status) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'transaction_date DESC',
    );
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getTransactionsByProductType(String productType) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'product_type = ?',
      whereArgs: [productType],
      orderBy: 'transaction_date DESC',
    );
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getTransactionsByCurrency(String currency) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'currency = ?',
      whereArgs: [currency],
      orderBy: 'transaction_date DESC',
    );
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<Map<String, double>> getPortfolioSummary() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT currency, SUM(amount) as total_amount
      FROM transactions
      WHERE status IN ('Active', 'Pending')
      GROUP BY currency
    ''');
    return {
      for (final row in result)
        row['currency'] as String: (row['total_amount'] as num).toDouble(),
    };
  }
}
