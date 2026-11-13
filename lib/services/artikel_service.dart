import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/artikel_model.dart';

class ArtikelService {
  final String baseUrl = 'http://10.0.2.2:8000/api/artikel-edukasi';

  Future<List<ItemDataModel>> fetchArtikel({String? jenis}) async {
    String url = baseUrl;
    if (jenis != null && jenis.isNotEmpty && jenis != 'All') {
      String queryJenis = jenis.toLowerCase();
      // Memetakan filter 'Event' ke 'acara' dan 'edukasi'/'artikel' sesuai data database
      if (jenis == 'Event') {
        queryJenis = 'acara';
      }
      url += '?jenis=$queryJenis';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List data = jsonResponse['data'];
        return data.map((item) => ItemDataModel.fromJson(item)).toList();
      } else {
        throw Exception('Server merespons dengan kode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }
}