import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _headers({
    String? token,
    bool json = true,
  }) {
    final headers = <String, String>{};

    if (json) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    } else {
      headers['Accept'] = 'application/json';
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<http.Response> get(
    String path, {
    bool auth = false,
  }) async {
    String? token;
    if (auth) token = await _getToken();

    return http.get(
      Uri.parse('${AppConst.baseUrl}$path'),
      headers: _headers(token: token, json: false),
    );
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    String? token;
    if (auth) token = await _getToken();

    return http.post(
      Uri.parse('${AppConst.baseUrl}$path'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    String? token;
    if (auth) token = await _getToken();

    return http.patch(
      Uri.parse('${AppConst.baseUrl}$path'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    String? token;
    if (auth) token = await _getToken();

    return http.put(
      Uri.parse('${AppConst.baseUrl}$path'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(
    String path, {
    bool auth = false,
  }) async {
    String? token;
    if (auth) token = await _getToken();

    return http.delete(
      Uri.parse('${AppConst.baseUrl}$path'),
      headers: _headers(token: token),
    );
  }

  static Future<http.StreamedResponse> postMultipart(
    String path, {
    required Map<String, String> fields,
    Map<String, String>? files,
    bool auth = false,
  }) async {
    String? token;
    if (auth) token = await _getToken();

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConst.baseUrl}$path'),
    );

    req.headers['Accept'] = 'application/json';

    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    fields.forEach((k, v) => req.fields[k] = v);

    if (files != null) {
      for (final entry in files.entries) {
        final path = entry.value;
        final ext = path.split('.').last.toLowerCase();
        MediaType? contentType;
        if (ext == 'jpg' || ext == 'jpeg') {
          contentType = MediaType('image', 'jpeg');
        } else if (ext == 'png') {
          contentType = MediaType('image', 'png');
        } else if (ext == 'pdf') {
          contentType = MediaType('application', 'pdf');
        }
        req.files.add(await http.MultipartFile.fromPath(entry.key, path, contentType: contentType));
      }
    }

    return req.send();
  }

  static Future<http.StreamedResponse> sendMultipart(
    String path, {
    String method = 'PATCH',
    required Map<String, String> fields,
    Map<String, String>? files,
    bool auth = false,
  }) async {
    String? token;
    if (auth) token = await _getToken();

    final req = http.MultipartRequest(
      method.toUpperCase(),
      Uri.parse('${AppConst.baseUrl}$path'),
    );

    req.headers['Accept'] = 'application/json';

    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    fields.forEach((k, v) => req.fields[k] = v);

    if (files != null) {
      for (final entry in files.entries) {
        final path = entry.value;
        final ext = path.split('.').last.toLowerCase();
        MediaType? contentType;
        if (ext == 'jpg' || ext == 'jpeg') {
          contentType = MediaType('image', 'jpeg');
        } else if (ext == 'png') {
          contentType = MediaType('image', 'png');
        } else if (ext == 'pdf') {
          contentType = MediaType('application', 'pdf');
        }
        req.files.add(await http.MultipartFile.fromPath(entry.key, path, contentType: contentType));
      }
    }

    return req.send();
  }

  static Future<Map<String, dynamic>> getStatistikBeranda() async {
    final res = await get('/api/beranda/statistik');
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Gagal mengambil statistik beranda');
  }

  static Future<List<dynamic>> getAktivitasBeranda() async {
    final res = await get('/api/beranda/aktivitas');
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['data'] as List<dynamic>?) ?? [];
      }
      return [];
    }
    throw Exception('Gagal mengambil aktivitas beranda');
  }

  static Future<http.Response> getBarang({bool auth = false}) {
    return get('/api/barang', auth: auth);
  }

  static Future<http.Response> getPeminjaman({bool auth = false}) {
    return get('/api/peminjaman', auth: auth);
  }

  static Future<http.Response> getNotifikasi({bool auth = true}) {
    return get('/notifikasi', auth: auth);
  }

  static Future<http.Response> login(Map<String, dynamic> body) {
    return post('/api/login', body);
  }

  static Future<http.Response> register(Map<String, dynamic> body) {
    return post('/api/register', body);
  }

  static Future<http.Response> logout({bool auth = true}) {
    return get('/logout', auth: auth);
  }
}