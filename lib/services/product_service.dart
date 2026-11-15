import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  // IP 10.0.2.2 untuk emulator Android (atau IP Laptop misal 192.168.x.x untuk HP fisik)
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String baseUrl = 'http://127.0.0.1:8000/api'; 

  Future<List<ProductModel>> getKatalogProduk(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/produk'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token', // Kirim token Sanctum
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> listData = body['data'];
      return listData.map((item) => ProductModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal mengambil data produk: ${response.statusCode}');
    }
  }
}