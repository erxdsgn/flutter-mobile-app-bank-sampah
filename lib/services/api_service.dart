import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Header default
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Helper untuk mendapatkan header dengan token Bearer
  // PERBAIKAN: Menambahkan tipe data Map<String, String> di dalam Future
  static Future<Map<String, String>> headersAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // GET Request
  static Future<http.Response> get(String endpoint) async {
    final authHeaders = await headersAuth();

    return await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: authHeaders,
    );
  }

  // POST Request
  static Future<http.Response> post(
    String endpoint, {
    required String body,
  }) async {
    final authHeaders = await headersAuth();

    return await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: authHeaders,
      body: body,
    );
  }

  // PUT Request (Baru ditambahkan untuk update data)
  static Future<http.Response> put(
    String endpoint, {
    required String body,
  }) async {
    final authHeaders = await headersAuth();

    return await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: authHeaders,
      body: body,
    );
  }
}