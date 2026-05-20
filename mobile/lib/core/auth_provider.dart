import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;
  bool _loading = false;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get loading => _loading;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final raw = prefs.getString('user');
    if (raw != null) _user = jsonDecode(raw);
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.post('/api/login', {'email': email, 'password': password});
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _token = data['token'];
        _user = Map<String, dynamic>.from(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(_user));
        _loading = false;
        notifyListeners();
        return null; // sukses
      }
      _loading = false;
      notifyListeners();
      return data['message'] ?? 'Login gagal.';
    } catch (e) {
      _loading = false;
      notifyListeners();
      return 'Tidak dapat terhubung ke server.';
    }
  }

  Future<String?> register(String nim, String nama, String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.post('/api/register', {
        'nim': nim,
        'nama': nama,
        'email': email,
        'password': password,
        'role': 'anggota',
      });
      final data = jsonDecode(res.body);
      _loading = false;
      notifyListeners();
      if (data['success'] == true) return null;
      return data['message'] ?? 'Registrasi gagal.';
    } catch (e) {
      _loading = false;
      notifyListeners();
      return 'Tidak dapat terhubung ke server.';
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
