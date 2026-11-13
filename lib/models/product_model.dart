
class ProductModel {
  /// Base URL storage Laravel.
  static const String storageUrl = 'http://10.0.2.2:8000/storage/';

  final int idProduk;
  final String namaProduk;
  final String? deskripsi;
  final double harga;
  final int stok;
  final String? foto;
  final String? nomorWa;
  final String? tanggalUpload;

  ProductModel({
    required this.idProduk,
    required this.namaProduk,
    required this.harga,
    required this.stok,
    this.deskripsi,
    this.foto,
    this.nomorWa,
    this.tanggalUpload,
  });

  /// Membaca data produk dari JSON Laravel.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      idProduk: int.tryParse('${json['id_produk'] ?? 0}') ?? 0,

      namaProduk: json['nama_produk']?.toString() ?? '',

      // Membaca deskripsi dari API Laravel.
      deskripsi: _parseDeskripsi(json['deskripsi']),

      harga: double.tryParse('${json['harga'] ?? 0}') ?? 0.0,

      stok: int.tryParse('${json['stok'] ?? 0}') ?? 0,

      foto: json['foto']?.toString(),

      nomorWa: json['nomor_wa']?.toString(),

      tanggalUpload: json['tanggal_upload']?.toString(),
    );
  }

  /// Membersihkan dan membaca deskripsi produk.
  static String? _parseDeskripsi(dynamic value) {
    if (value == null) return null;

    final String result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return null;
    }

    return result;
  }

  /// URL foto lengkap.
  String get fotoUrl {
    if (foto == null || foto!.trim().isEmpty) {
      return '';
    }

    return '$storageUrl${foto!.trim()}';
  }

  /// Format harga produk.
  String get hargaFormatted =>
      'Rp ${harga.toStringAsFixed(0)}';

  /// Memeriksa apakah produk memiliki deskripsi.
  bool get punyaDeskripsi =>
      deskripsi != null && deskripsi!.trim().isNotEmpty;

}
