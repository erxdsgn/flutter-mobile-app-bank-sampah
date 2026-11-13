import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/item_setoran_model.dart';
import '../models/kategori_sampah_model.dart';
import '../models/transaksi_model.dart';

class SetoranService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const Duration _timeout = Duration(seconds: 20);

  /// Mengambil pesan error dari response Laravel ('errors' pada 422, atau
  /// 'message'). Aman terhadap response non-JSON (mis. halaman error 500).
  String _extractMessage(http.Response response, String fallback) {
    if (response.statusCode == 401) {
      return 'Sesi berakhir, silakan login ulang.';
    }
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
        final message = body['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // body bukan JSON, pakai pesan bawaan
    }
    return fallback;
  }

  // ==========================================
  // 1. MENGAMBIL KATEGORI SAMPAH
  // ==========================================
  Future<List<KategoriSampahModel>> getKategori(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/kategori-sampah'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> data = responseData['data'];
      return data.map((item) => KategoriSampahModel.fromJson(item)).toList();
    } else {
      throw Exception(
        _extractMessage(response, 'Gagal memuat kategori sampah.'),
      );
    }
  }

  // ==========================================
  // 2. MENGIRIM SETORAN SAMPAH MULTI-ITEM
  // ==========================================
  Future<bool> submitSetoran({
    required String token,
    required List<ItemSetoranModel> items,
    File? foto,
  }) async {
    if (items.isEmpty) {
      throw Exception('Pilih minimal 1 jenis sampah.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/setor-sampah'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // Format yang dikirim: [{"id_kategori": 1, "jumlah": 3.0}, ...]
    request.fields['items'] = jsonEncode(
      items.map((item) => item.toJson()).toList(),
    );

    if (foto != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto_sampah', foto.path),
      );
    }

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    }
    throw Exception(_extractMessage(response, 'Gagal mengirim setoran.'));
  }

  // ==========================================
  // 3. MENGAMBIL RIWAYAT TRANSAKSI
  // ==========================================
  Future<List<TransaksiModel>> getHistory(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/riwayat-setoran'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      
      // Mengatasi respon berbentuk List langsung [...] atau Object {"data": [...]}
      final List<dynamic> data = body is List 
          ? body 
          : (body['data'] is List ? body['data'] : []);

      return data.map((item) => TransaksiModel.fromJson(item)).toList();
    } else {
      throw Exception(
        _extractMessage(response, 'Gagal memuat riwayat transaksi.'),
      );
    }
  }
}