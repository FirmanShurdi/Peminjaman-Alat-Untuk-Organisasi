import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;
  int get itemCount => _items.length;

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('cart');
    if (str != null) {
      try {
        final List<dynamic> decoded = jsonDecode(str);
        _items = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> addItem(Map<String, dynamic> item, {int quantity = 1}) async {
    final stok = item['stok'] ?? 0;
    
    // Cek apakah item sudah ada di keranjang berdasarkan id_barang
    final existsIndex = _items.indexWhere((i) => i['id_barang'] == item['id_barang']);
    if (existsIndex >= 0) {
      final currentQty = _items[existsIndex]['jumlah'] ?? 1;
      if (currentQty + quantity > stok) {
        throw Exception('Stok tidak cukup! Barang ini sudah ada $currentQty unit di keranjang.');
      }
      // Tambah kuantitas jika sudah ada
      _items[existsIndex]['jumlah'] = currentQty + quantity;
    } else {
      if (quantity > stok) {
        throw Exception('Kuantitas melebihi stok yang tersedia!');
      }
      final newItem = Map<String, dynamic>.from(item);
      newItem['jumlah'] = quantity;
      _items.add(newItem);
    }
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeItem(dynamic idBarang) async {
    _items.removeWhere((item) => item['id_barang'] == idBarang);
    await _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart', jsonEncode(_items));
  }
}
