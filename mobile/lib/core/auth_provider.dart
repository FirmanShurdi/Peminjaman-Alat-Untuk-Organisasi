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
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get loading => _loading;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    final rawUser = prefs.getString('user');
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        _user = jsonDecode(rawUser) as Map<String, dynamic>;
      } catch (_) {
        _user = null;
      }
    }

    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await ApiService.login({
        'email': email,
        'password': password,
      });

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        _token = data['token'];
        _user = data['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['user'])
            : null;

        final prefs = await SharedPreferences.getInstance();
        if (_token != null) {
          await prefs.setString('token', _token!);
        }
        if (_user != null) {
          await prefs.setString('user', jsonEncode(_user));
        }

        _loading = false;
        notifyListeners();
        return null;
      }

      _loading = false;
      notifyListeners();
      return data['message'] ?? 'Login gagal.';
    } catch (_) {
      _loading = false;
      notifyListeners();
      return 'Tidak dapat terhubung ke server.';
    }
  }

  Future<String?> register(
    String nim,
    String nama,
    String email,
    String password,
    String mfaCode,
  ) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await ApiService.register({
        'nim': nim,
        'nama': nama,
        'email': email,
        'password': password,
        'role': 'anggota',
        'mfaCode': mfaCode,
      });

      final data = jsonDecode(res.body);

      _loading = false;
      notifyListeners();

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['success'] == true) {
        return null;
      }

      return data['message'] ?? 'Registrasi gagal.';
    } catch (_) {
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