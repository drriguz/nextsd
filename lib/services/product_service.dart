import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tranche.dart';

class ProductService {
  List<Tranche>? _tranches;

  List<Tranche>? get tranches => _tranches;

  Future<List<Tranche>> loadProducts() async {
    if (_tranches != null) return _tranches!;

    final jsonString = await rootBundle.loadString('assets/products.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final items = data['rmwGenericResponse']['items'] as List<dynamic>;

    _tranches = items
        .map((item) => Tranche.fromJson(item as Map<String, dynamic>))
        .toList();

    return _tranches!;
  }
}
