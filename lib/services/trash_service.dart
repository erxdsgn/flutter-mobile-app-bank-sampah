// lib/services/trash_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trash_price_model.dart';
import 'api_service.dart'; // Menggunakan base URL dari ApiService yang sudah ada di proyek Anda

class TrashService {
  // Mengambil daftar harga sampah dari Laravel API
  Future<List<TrashPrice>> getHargaSampah({String? search}) async {
    try {
      // Sesuaikan endpoint dengan route Laravel Anda (misal: /api/harga-sampah)
      String url = '${ApiService.baseUrl}/harga-sampah';
      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['data'];
        return data.map((json) => TrashPrice.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat data harga sampah dari server.');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}