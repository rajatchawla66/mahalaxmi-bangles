import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_state.dart';
import '../models/cart_item.dart';

class CartPersistenceService {
  static String _key(int customerId) => 'customer_cart_$customerId';

  static Future<void> save(int customerId, CartState state) async {
    final prefs = await SharedPreferences.getInstance();
    if (state.lines.isEmpty) {
      await prefs.remove(_key(customerId));
      return;
    }
    final json = state.items.map((item) => item.toJson()).toList();
    await prefs.setString(_key(customerId), jsonEncode(json));
  }

  static Future<List<CartItem>?> load(int customerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(customerId));
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CartPersistenceService: corrupt data, clearing: $e');
      await prefs.remove(_key(customerId));
      return null;
    }
  }

  static Future<void> clear(int customerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(customerId));
  }
}
