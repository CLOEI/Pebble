import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Snack {
  final String id;
  final String name;
  final String category;
  final String serving;
  final int kcal;
  final double protein;

  const Snack({
    required this.id,
    required this.name,
    required this.category,
    required this.serving,
    required this.kcal,
    required this.protein,
  });

  factory Snack.fromJson(Map<String, dynamic> j) => Snack(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        serving: j['serving'] as String,
        kcal: (j['kcal'] as num).toInt(),
        protein: (j['protein'] as num).toDouble(),
      );
}

class SnackRepository {
  static List<Snack>? _cache;

  static const List<String> categories = [
    'Biscuits & Cookies',
    'Chips & Savory',
    'Chocolates & Sweets',
    'Noodle Snacks',
    'Cakes & Bakery',
  ];

  static Future<List<Snack>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/snacks.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _cache = list.map(Snack.fromJson).toList();
    return _cache!;
  }

  static List<Snack> filter(
    List<Snack> all, {
    String? category,
    int? maxKcal,
    String? query,
  }) {
    return all.where((s) {
      if (category != null && s.category != category) return false;
      if (maxKcal != null && s.kcal > maxKcal) return false;
      if (query != null && query.isNotEmpty &&
          !s.name.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }
}
