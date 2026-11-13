import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // <-- TAMBAHKAN IMPORT INI
import '../models/jadwal_setoran_model.dart';

class JadwalSetoranService {
  // Disesuaikan tanpa /v1
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  /// Mengambil seluruh jadwal setoran dari backend Laravel
  Future<List<JadwalSetoran>> getJadwalSetoran() async {
    try {
      // 1. Ambil token dari penyimpanan lokal (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
      }

      // 2. Tembak API dengan menyertakan Token Bearer
      final response = await http.get(
        Uri.parse('$baseUrl/jadwal-setoran'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // <-- INI KUNCI UTAMANYA
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> listData = body['data'];
          return listData
              .map((item) => JadwalSetoran.fromJson(item))
              .toList();
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Sesi Anda telah berakhir. Silakan login ulang.');
      } else {
        throw Exception('Gagal memuat data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }
}