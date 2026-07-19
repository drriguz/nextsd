class Transaction {
  final int? id;
  final String transactionDate;
  final String productType;
  final String trancheName;
  final String currency;
  final double amount;
  final String status;
  final String tenor;
  final double? coupon;
  final String? strike;
  final String? underlyingAsset;
  final String? settlementDate;
  final String? maturityDate;
  final double? pnl;
  final String remarks;

  Transaction({
    this.id,
    required this.transactionDate,
    required this.productType,
    required this.trancheName,
    required this.currency,
    required this.amount,
    required this.status,
    required this.tenor,
    this.coupon,
    this.strike,
    this.underlyingAsset,
    this.settlementDate,
    this.maturityDate,
    this.pnl,
    this.remarks = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_date': transactionDate,
      'product_type': productType,
      'tranche_name': trancheName,
      'currency': currency,
      'amount': amount,
      'status': status,
      'tenor': tenor,
      'coupon': coupon,
      'strike': strike,
      'underlying_asset': underlyingAsset,
      'settlement_date': settlementDate,
      'maturity_date': maturityDate,
      'pnl': pnl,
      'remarks': remarks,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      transactionDate: map['transaction_date'] as String,
      productType: map['product_type'] as String,
      trancheName: map['tranche_name'] as String,
      currency: map['currency'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String,
      tenor: map['tenor'] as String,
      coupon: (map['coupon'] as num?)?.toDouble(),
      strike: map['strike'] as String?,
      underlyingAsset: map['underlying_asset'] as String?,
      settlementDate: map['settlement_date'] as String?,
      maturityDate: map['maturity_date'] as String?,
      pnl: (map['pnl'] as num?)?.toDouble(),
      remarks: map['remarks'] as String? ?? '',
    );
  }

  String get formattedAmount {
    final buf = StringBuffer();
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
}
