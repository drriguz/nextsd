import 'package:flutter/widgets.dart';
import '../services/locale_provider.dart';

class AppStrings {
  final LocaleProvider _locale;

  AppStrings(this._locale);

  static AppStrings of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_L10nScope>()!.strings;
  }

  // --- Tabs & Filters ---
  String get productsOnSale => isZh ? '在售产品' : 'Products on Sale';
  String get comingSoon => isZh ? '即将开售' : 'Coming Soon';
  String get filter => isZh ? '筛选' : 'Filter';
  String get filterAll => isZh ? '筛选: 全部' : 'Filter: All';
  String filterBy(String segment) => isZh ? '筛选: ${segmentZh(segment)}' : 'Filter: $segment';
  String productCount(int n) => isZh ? '$n个产品' : '$n products';

  // --- Bottom Tabs ---
  String get tabHome => isZh ? '首页' : 'Home';
  String get tabMy => isZh ? '我的' : 'My';
  String get tabTransfer => isZh ? '转账' : 'Transfer';
  String get tabWealth => isZh ? '理财' : 'Wealth';
  String get tabSettings => isZh ? '设置' : 'Settings';

  // --- Home ---
  String get welcomeBack => isZh ? '欢迎回来' : 'Welcome Back';
  String get quickActions => isZh ? '快捷功能' : 'Quick Actions';
  String get structuredDeposit => isZh ? '结构存款' : 'Structured Deposit';
  String get fund => isZh ? '基金' : 'Fund';
  String get foreignExchange => isZh ? '外汇' : 'Foreign Exchange';
  String get insurance => isZh ? '保险' : 'Insurance';
  String get bonds => isZh ? '债券' : 'Bonds';
  String get more => isZh ? '更多' : 'More';
  String get accountBalance => isZh ? '账户余额' : 'Account Balance';
  String get totalAssets => isZh ? '总资产' : 'Total Assets';

  // --- My ---
  String get myProfile => isZh ? '个人资料' : 'My Profile';
  String get changePassword => isZh ? '修改密码' : 'Change Password';
  String get notificationSettings => isZh ? '通知设置' : 'Notification Settings';
  String get biometric => isZh ? '生物识别' : 'Biometric';
  String get statement => isZh ? '账单/报表' : 'Statements';
  String get helpCenter => isZh ? '帮助中心' : 'Help Center';
  String get aboutUs => isZh ? '关于我们' : 'About Us';
  String get logout => isZh ? '退出登录' : 'Log Out';

  // --- Transfer ---
  String get transfer => isZh ? '转账' : 'Transfer';
  String get transferToOwn => isZh ? '同名转账' : 'To Own Account';
  String get transferToOthers => isZh ? '他人转账' : 'To Others';
  String get internationalTransfer => isZh ? '跨境汇款' : 'International';
  String get transferHistory => isZh ? '转账记录' : 'Transfer History';
  String get fromAccount => isZh ? '付款账户' : 'From Account';
  String get toAccount => isZh ? '收款账户' : 'To Account';
  String get transferAmount => isZh ? '转账金额' : 'Amount';
  String get transferNow => isZh ? '立即转账' : 'Transfer Now';
  String get payeeName => isZh ? '收款人姓名' : 'Payee Name';
  String get bankName => isZh ? '收款银行' : 'Bank Name';
  String get remarksOptional => isZh ? '备注（选填）' : 'Remarks (Optional)';

  // --- Wealth ---
  String get wealth => isZh ? '理财' : 'Wealth';
  String get myInvestments => isZh ? '我的投资' : 'My Investments';
  String get browseProducts => isZh ? '浏览产品' : 'Browse Products';

  // --- Card labels ---
  String get riskRating => isZh ? '银行产品风险评级' : 'Bank Product Risk Rating';
  String get subscriptionPeriod => isZh ? '认购期' : 'Subscription Period';
  String get minInvestment => isZh ? '最低投资额' : 'Minimum Investment';
  String get investmentTenor => isZh ? '投资期限' : 'Investment Tenor';
  String get principalProtection => isZh ? '本金保障' : 'Principal Protection';
  String get underlyingAsset => isZh ? '挂钩标的' : 'Underlying Asset';
  String get nonProtected => isZh ? '非保本' : 'Non-Protected';
  String get qualifiedInvestor => isZh ? '合格投资者' : 'Qualified Investor';

  // --- Status ---
  String get onSale => isZh ? '在售' : 'On Sale';
  String get comingSoonBadge => isZh ? '即将开售' : 'Coming Soon';

  // --- Settings ---
  String get settings => isZh ? '设置' : 'Settings';
  String get accountInfo => isZh ? '账户信息' : 'Account Info';
  String get clientId => isZh ? '客户编号' : 'Client ID';
  String get preferredLanguage => isZh ? '首选语言' : 'Preferred Language';
  String get eligibleCities => isZh ? '适用城市' : 'Eligible Cities';
  String get modelSelection => isZh ? '模型选择' : 'Model Selection';
  String get defaultLabel => isZh ? '默认 (litertlm)' : 'Default (litertlm)';
  String get comingSoonLabel => isZh ? '即将推出' : 'Coming soon';
  String get verified => isZh ? '已验证' : 'Verified';
  String premiumClient(String segment) => isZh ? '尊享银行客户' : 'Premium Banking Client';
  String segmentLabel(String segment) => isZh ? '等级: $segment' : 'Segment: $segment';

  // --- Detail sheet ---
  String get productDetails => isZh ? '产品详情' : 'Product Details';
  String get subscription => isZh ? '认购信息' : 'Subscription';
  String get underlying => isZh ? '挂钩标的' : 'Underlying';
  String get returns => isZh ? '收益信息' : 'Returns';

  // --- Misc ---
  String get noProducts => isZh ? '暂无产品' : 'No products available';
  String get loadingFailed => isZh ? '加载失败' : 'Failed to load';
  String get clearFilter => isZh ? '清除筛选' : 'Clear Filter';
  String get filterTitle => isZh ? '筛选投资者类型' : 'Filter by Investor Type';

  // --- Search ---
  String get search => isZh ? '搜索' : 'Search';
  String get searchHint => isZh ? '搜索产品或交易...' : 'Search products or transactions...';
  String get searchProducts => isZh ? '产品' : 'Products';
  String get searchTransactions => isZh ? '交易' : 'Transactions';
  String get noResults => isZh ? '未找到结果' : 'No results found';
  String get searchResults => isZh ? '搜索结果' : 'Search Results';

  // --- Transactions ---
  String get transactions => isZh ? '交易记录' : 'Transactions';
  String get portfolio => isZh ? '投资组合' : 'Portfolio';
  String get totalInvestment => isZh ? '总投资额' : 'Total Investment';
  String get activePositions => isZh ? '持仓中' : 'Active';
  String get maturedPositions => isZh ? '已到期' : 'Matured';
  String get pendingPositions => isZh ? '待处理' : 'Pending';
  String get cancelledPositions => isZh ? '已取消' : 'Cancelled';
  String get transactionDate => isZh ? '交易日期' : 'Transaction Date';
  String get settlementDate => isZh ? '交割日' : 'Settlement Date';
  String get maturity => isZh ? '到期日' : 'Maturity';
  String get amount => isZh ? '金额' : 'Amount';
  String get tenor => isZh ? '期限' : 'Tenor';
  String get status => isZh ? '状态' : 'Status';
  String get pnl => isZh ? '盈亏' : 'P&L';
  String get remarks => isZh ? '备注' : 'Remarks';
  String get noTransactions => isZh ? '暂无交易记录' : 'No transactions';
  String transactionCount(int n) => isZh ? '$n笔交易' : '$n transactions';

  // --- Detail fields ---
  String detailLabel(String key) {
    final map = isZh ? _detailLabelsZh : _detailLabelsEn;
    return map[key] ?? key;
  }

  static const _detailLabelsEn = {
    'Product Type': 'Product Type',
    'Currency': 'Currency',
    'Tenor': 'Tenor',
    'Coupon': 'Coupon',
    'Coupon Frequency': 'Coupon Frequency',
    'Principal Protection': 'Principal Protection',
    'Strike': 'Strike',
    'KI Barrier': 'KI Barrier',
    'KO Barrier': 'KO Barrier',
    'Risk Rating': 'Risk Rating',
    'Subscription Period': 'Subscription Period',
    'Min Order': 'Min Order',
    'Denomination': 'Denomination',
    'Eligible Segments': 'Eligible Segments',
    'Eligible Cities': 'Eligible Cities',
    'Issuer': 'Issuer',
    'Open to QI': 'Open to QI',
    'Min Return p.a.': 'Min Return p.a.',
    'Max Return p.a.': 'Max Return p.a.',
    'Barrier Return p.a.': 'Barrier Return p.a.',
    'Barrier Level': 'Barrier Level',
    'Participation Rate': 'Participation Rate',
  };

  static const _detailLabelsZh = {
    'Product Type': '产品类型',
    'Currency': '币种',
    'Tenor': '投资期限',
    'Coupon': '票息',
    'Coupon Frequency': '票息频率',
    'Principal Protection': '本金保障',
    'Strike': '执行价',
    'KI Barrier': '敲入价',
    'KO Barrier': '敲出价',
    'Risk Rating': '风险评级',
    'Subscription Period': '认购期',
    'Min Order': '最低投资额',
    'Denomination': '递增单位',
    'Eligible Segments': '适用客群',
    'Eligible Cities': '适用城市',
    'Issuer': '发行人',
    'Open to QI': '开放合格投资者',
    'Min Return p.a.': '最低年化收益',
    'Max Return p.a.': '最高年化收益',
    'Barrier Return p.a.': '障碍年化收益',
    'Barrier Level': '障碍水平',
    'Participation Rate': '参与率',
  };

  String segmentZh(String en) {
    return _segmentMap[en] ?? en;
  }

  static const _segmentMap = {
    'Private': '私人银行',
    'Priority': '优先理财',
    'Premium': '高级理财',
    'Personal': '个人客户',
  };

  // --- Tenor display ---
  String formatTenor(String tenor) {
    if (isZh) {
      final m = RegExp(r'(\d+)M').firstMatch(tenor);
      if (m != null) return '${m.group(1)}个月';
      final y = RegExp(r'(\d+)Y').firstMatch(tenor);
      if (y != null) return '${y.group(1)}年';
      return tenor;
    }
    final m = RegExp(r'(\d+)M').firstMatch(tenor);
    if (m != null) return '${m.group(1)} Months';
    final y = RegExp(r'(\d+)Y').firstMatch(tenor);
    if (y != null) return '${y.group(1)} Years';
    return tenor;
  }

  // --- Date formatting ---
  String formatSubscriptionDate(String raw) {
    try {
      final parts = raw.split(' ').first.split('-');
      if (parts.length != 3) return raw;
      const monthNames = {
        'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
        'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
        'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
      };
      final month = monthNames[parts[1]] ?? parts[1];
      if (isZh) {
        return '${parts[2]}年$month月${parts[0]}日';
      }
      return '${parts[2]}-$month-${parts[0]}';
    } catch (_) {
      return raw;
    }
  }

  String formatSubscriptionPeriod(String? start, String? end) {
    if (start == null || end == null) return '-';
    return '${formatSubscriptionDate(start)} - ${formatSubscriptionDate(end)}';
  }

  // --- Currency ---
  String currencyName(String ccy) {
    if (isZh) {
      switch (ccy.toUpperCase()) {
        case 'CNY': return '人民币';
        case 'USD': return '美元';
        case 'HKD': return '港元';
        default: return ccy;
      }
    }
    return ccy;
  }

  // --- Product type CN name ---
  String productTypeName(String? productNameCN, String productEn) {
    if (isZh) {
      if (productNameCN != null && productNameCN.isNotEmpty) return productNameCN;
      return _productCnNames[productEn] ?? productEn;
    }
    return productEn;
  }

  static const _productCnNames = {
    'WoB Autocall': '一篮子标的自动触发赎回结构',
    'Snowball': '雪球自动赎回结构',
    'Range Accrual': '区间累积结构',
    'Averaging Autocall': '平均价格自动赎回结构',
  };

  bool get isZh => _locale.isZh;
}

class _L10nScope extends InheritedWidget {
  final AppStrings strings;

  const _L10nScope({
    required this.strings,
    required super.child,
  });

  @override
  bool updateShouldNotify(_L10nScope old) => strings != old.strings;
}

class L10nProvider extends StatefulWidget {
  final LocaleProvider localeProvider;
  final Widget child;

  const L10nProvider({
    super.key,
    required this.localeProvider,
    required this.child,
  });

  @override
  State<L10nProvider> createState() => _L10nProviderState();
}

class _L10nProviderState extends State<L10nProvider> {
  late AppStrings _strings;

  @override
  void initState() {
    super.initState();
    _strings = AppStrings(widget.localeProvider);
    widget.localeProvider.addListener(_onLocaleChange);
  }

  void _onLocaleChange() {
    setState(() {
      _strings = AppStrings(widget.localeProvider);
    });
  }

  @override
  void dispose() {
    widget.localeProvider.removeListener(_onLocaleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _L10nScope(
      strings: _strings,
      child: widget.child,
    );
  }
}
