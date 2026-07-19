class Tranche {
  final String productName;
  final String? productNameCN;
  final String product;
  final String ccy;
  final String? nmID;
  final String trancheName;
  final String status;
  final List<String>? underlying;
  final List<String>? underlyingName;
  final String tenor;
  final String? strike;
  final String? ki;
  final String? ko;
  final String? coupon;
  final String? couponFreq;
  final String? prr;
  final String? principalProtection;
  final String? issuer;
  final String? minOrder;
  final String? denomination;
  final String? eligibleSegments;
  final String? eligibleCities;
  final String? minReturnPA;
  final String? maxReturnPA;
  final String? barrierReturnPA;
  final String? barrierPercent;
  final String? participationRate;
  final String? totalSubscription;
  final String? productCategory;
  final String? hedgingType;
  final String? windowPeriodStartDate;
  final String? windowPeriodEndDate;
  final String? openToQI;
  final List<String>? market;
  final List<String>? exchange;

  Tranche({
    required this.productName,
    this.productNameCN,
    required this.product,
    required this.ccy,
    this.nmID,
    required this.trancheName,
    required this.status,
    this.underlying,
    this.underlyingName,
    required this.tenor,
    this.strike,
    this.ki,
    this.ko,
    this.coupon,
    this.couponFreq,
    this.prr,
    this.principalProtection,
    this.issuer,
    this.minOrder,
    this.denomination,
    this.eligibleSegments,
    this.eligibleCities,
    this.minReturnPA,
    this.maxReturnPA,
    this.barrierReturnPA,
    this.barrierPercent,
    this.participationRate,
    this.totalSubscription,
    this.productCategory,
    this.hedgingType,
    this.windowPeriodStartDate,
    this.windowPeriodEndDate,
    this.openToQI,
    this.market,
    this.exchange,
  });

  factory Tranche.fromJson(Map<String, dynamic> json) {
    return Tranche(
      productName: json['productName'] as String? ?? '',
      productNameCN: json['productNameCN'] as String?,
      product: json['product'] as String? ?? '',
      ccy: json['ccy'] as String? ?? '',
      nmID: json['nmID']?.toString(),
      trancheName: json['trancheName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      underlying: (json['underlying'] as List<dynamic>?)?.cast<String>(),
      underlyingName: (json['underlyingName'] as List<dynamic>?)?.cast<String>(),
      tenor: json['tenor'] as String? ?? '',
      strike: json['strike']?.toString(),
      ki: json['ki']?.toString(),
      ko: json['ko']?.toString(),
      coupon: json['coupon']?.toString(),
      couponFreq: json['couponFreq'] as String?,
      prr: json['prr']?.toString(),
      principalProtection: json['principalProtection']?.toString(),
      issuer: json['issuer'] as String?,
      minOrder: json['minOrder']?.toString(),
      denomination: json['denomination']?.toString(),
      eligibleSegments: json['eligibleSegments'] as String?,
      eligibleCities: json['eligibleCities'] as String?,
      minReturnPA: json['minReturnPA']?.toString(),
      maxReturnPA: json['maxReturnPA']?.toString(),
      barrierReturnPA: json['barrierReturnPA']?.toString(),
      barrierPercent: json['barrierPercent']?.toString(),
      participationRate: json['participationRate']?.toString(),
      totalSubscription: json['totalSubscription']?.toString(),
      productCategory: json['productCategory'] as String?,
      hedgingType: json['hedgingType'] as String?,
      windowPeriodStartDate: json['windowPeriodStartDate'] as String?,
      windowPeriodEndDate: json['windowPeriodEndDate'] as String?,
      openToQI: json['openToQI'] as String?,
      market: (json['market'] as List<dynamic>?)?.cast<String>(),
      exchange: (json['exchange'] as List<dynamic>?)?.cast<String>(),
    );
  }

  String get displayName => productNameCN ?? productCnName;

  static const _productCnNames = {
    'WoB Autocall': '一篮子标的自动触发赎回结构',
    'Snowball': '雪球自动赎回结构',
    'Range Accrual': '区间累积结构',
    'Averaging Autocall': '平均价格自动赎回结构',
  };

  String get productCnName {
    if (productNameCN != null && productNameCN!.isNotEmpty) return productNameCN!;
    return _productCnNames[product] ?? product;
  }

  String get currencyName {
    switch (ccy.toUpperCase()) {
      case 'CNY':
        return '人民币';
      case 'USD':
        return '美元';
      case 'HKD':
        return '港元';
      default:
        return ccy;
    }
  }

  String get formattedMinOrder {
    if (minOrder == null) return '-';
    final n = int.tryParse(minOrder!);
    if (n == null) return minOrder!;
    return _formatNumber(n);
  }

  String get formattedTenor {
    if (tenor.isEmpty) return '-';
    final m = RegExp(r'(\d+)M').firstMatch(tenor);
    if (m != null) return '${m.group(1)}个月';
    final y = RegExp(r'(\d+)Y').firstMatch(tenor);
    if (y != null) return '${y.group(1)}年';
    return tenor;
  }

  String get formattedProtection {
    if (principalProtection == null) return '-';
    final v = double.tryParse(principalProtection!);
    if (v == null) return '$principalProtection%';
    if (v == v.truncateToDouble()) {
      return '${v.toInt()}%';
    }
    return '${v.toStringAsFixed(1)}%';
  }

  String get formattedSubscriptionPeriod {
    if (windowPeriodStartDate == null || windowPeriodEndDate == null) return '-';
    final start = _formatDate(windowPeriodStartDate!);
    final end = _formatDate(windowPeriodEndDate!);
    return '$start - $end';
  }

  String _formatDate(String raw) {
    try {
      final parts = raw.split(' ').first.split('-');
      if (parts.length != 3) return raw;
      final monthNames = {
        'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
        'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
        'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
      };
      final month = monthNames[parts[1]] ?? parts[1];
      return '${parts[2]}年$month月${parts[0]}日';
    } catch (_) {
      return raw;
    }
  }

  static String _formatNumber(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  bool get isOpen {
    final lower = status.toLowerCase();
    if (!lower.contains('open')) return false;
    if (windowPeriodStartDate == null || windowPeriodEndDate == null) return true;
    final now = DateTime.now();
    final start = _tryParseDate(windowPeriodStartDate!);
    final end = _tryParseDate(windowPeriodEndDate!);
    if (start == null || end == null) return true;
    return now.isAfter(start) && now.isBefore(end);
  }

  bool get isComingSoon {
    final lower = status.toLowerCase();
    if (!lower.contains('open')) return false;
    if (windowPeriodStartDate == null) return false;
    final start = _tryParseDate(windowPeriodStartDate!);
    if (start == null) return false;
    return DateTime.now().isBefore(start);
  }

  DateTime? _tryParseDate(String raw) {
    try {
      final parts = raw.split(' ').first.split('-');
      if (parts.length != 3) return null;
      final monthNames = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
        'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
        'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final month = monthNames[parts[1]];
      if (month == null) return null;
      return DateTime(int.parse(parts[2]), month, int.parse(parts[0]));
    } catch (_) {
      return null;
    }
  }

  List<String> get segmentTags {
    if (eligibleSegments == null || eligibleSegments!.isEmpty) return [];
    return eligibleSegments!.split(',').map((s) => s.trim()).toList();
  }

  bool get isQIOnly => openToQI == 'Yes';

  bool get isPrincipalProtected {
    if (principalProtection == null) return false;
    final v = double.tryParse(principalProtection!);
    return v != null && v >= 100;
  }

  List<String> get badges {
    final result = <String>[];
    if (!isPrincipalProtected) result.add('非保本');
    if (isQIOnly) result.add('合格投资者');
    return result;
  }

  String get underlyingDisplay {
    if (underlying == null || underlying!.isEmpty) return '';
    final lines = StringBuffer();
    for (var i = 0; i < underlying!.length; i++) {
      final prefix = market != null && i < market!.length ? market![i] : '';
      lines.writeln('$prefix${underlying![i]}');
    }
    return lines.toString().trimRight();
  }
}
