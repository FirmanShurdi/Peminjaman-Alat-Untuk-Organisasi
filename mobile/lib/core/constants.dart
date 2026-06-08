import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConst {
  static const String _envIp = String.fromEnvironment('SERVER_IP');
  static const String _envPort = String.fromEnvironment('SERVER_PORT');

  static String get _port {
    if (_envPort.isNotEmpty) return _envPort;
    return '5000'; // Sesuaikan dengan port VM1 API Node.js
  }

  static String get baseUrl {
    if (_envIp.isNotEmpty) {
      return 'http://$_envIp:$_port';
    }

    if (kIsWeb) {
      return 'http://localhost:$_port';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_port';
    }

    return 'http://localhost:$_port';
  }

  // Base URL khusus untuk gambar (mengarah ke Laragon Windows/Backend di port 3000)
  static String get imageBaseUrl {
    if (_envIp.isNotEmpty) {
      return 'http://$_envIp:$_port';
    }
    if (kIsWeb) {
      return 'http://localhost:$_port';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_port';
    }
    return 'http://localhost:$_port';
  }

  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color bg = Color(0xFFF8FAFC);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}