import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _headers({String? token, bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  // ─── GET ────────────────────────────────────────────────
  static Future<http.Response> get(String path, {bool auth = false}) async {
    String? token;
    if (auth) token = await _getToken();
    return http.get(
      Uri.parse('${AppConst.baseUrl}$path'),
      headers: _headers(token: token),
    );
  }

  // ─── POST JSON ──────────────────────────────────────────
  static Future<http.Response> post(String path, Map<String, dynamic> body, {bool auth = false}) async {
    String? token;
    if (auth) token = await _getToken();
    return http.post(
      Uri.parse('${AppConst.baseUrl}$path'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
  }

  // ─── POST Multipart ─────────────────────────────────────
  static Future<http.StreamedResponse> postMultipart(
    String path, {
    required Map<String, String> fields,
    Map<String, String>? files, // key -> filePath
    bool auth = false,
  }) async {
    String? token;
    if (auth) token = await _getToken();
    final req = http.MultipartRequest('POST', Uri.parse('${AppConst.baseUrl}$path'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    fields.forEach((k, v) => req.fields[k] = v);
    if (files != null) {
      for (final e in files.entries) {
        req.files.add(await http.MultipartFile.fromPath(e.key, e.value));
      }
    }
    return req.send();
  }

  // ─── PATCH JSON ─────────────────────────────────────────
  static Future<http.Response> patch(String path, Map<String, dynamic> body, {bool auth = false}) async {
    String? token;
    if (auth) token = await _getToken();
    return http.patch(
      Uri.parse('${AppConst.baseUrl}$path'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
  }

  // ─── PATCH Multipart ────────────────────────────────────
  static Future<http.StreamedResponse> patchMultipart(
    String path, {
    required Map<String, String> fields,
    Map<String, String>? files,
    bool auth = false,
  }) async {
    String? token;
    if (auth) token = await _getToken();
    final req = http.MultipartRequest('PATCH', Uri.parse('${AppConst.baseUrl}$path'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    fields.forEach((k, v) => req.fields[k] = v);
    if (files != null) {
      for (final e in files.entries) {
        req.files.add(await http.MultipartFile.fromPath(e.key, e.value));
      }
    }
    return req.send();
  }
}
