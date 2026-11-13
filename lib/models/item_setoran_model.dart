import 'kategori_sampah_model.dart';

class ItemSetoranModel {
  final KategoriSampahModel kategori;
  double jumlah;

  ItemSetoranModel({
    required this.kategori,
    required this.jumlah,
  });

  double get subtotal => kategori.hargaSatuan * jumlah;

  Map<String, dynamic> toJson() {
    return {
      'id_kategori': kategori.idKategori,
      'jumlah': jumlah,
    };
  }
}