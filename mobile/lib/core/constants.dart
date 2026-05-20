import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

class AppConst {
  static const String _envIp = String.fromEnvironment('SERVER_IP');

  static String get baseUrl {
    if (_envIp.isNotEmpty) return 'http://$_envIp:3000';
    
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000'; // Windows, macOS, dll
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
