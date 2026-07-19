import 'package:flutter/foundation.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'zh';

  String get locale => _locale;
  bool get isZh => _locale == 'zh';

  void setLocale(String value) {
    if (value == _locale) return;
    _locale = value;
    notifyListeners();
  }
}
