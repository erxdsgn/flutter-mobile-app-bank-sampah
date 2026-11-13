class KategoriSampahModel {
  final int idKategori;
  final String namaKategori;
  final String satuan;
  final double hargaSatuan;

  KategoriSampahModel({
    required this.idKategori,
    required this.namaKategori,
    required this.satuan,
    required this.hargaSatuan,
  });

  factory KategoriSampahModel.fromJson(Map<String, dynamic> json) {
    return KategoriSampahModel(
      idKategori: json['id_kategori'],
      namaKategori: json['nama_kategori'],
      satuan: json['satuan'],
      hargaSatuan: double.parse(json['harga_satuan'].toString()),
    );
  }

  // Sama jika id-nya sama, supaya pilihan dropdown tetap valid walaupun
  // daftar kategori dimuat ulang.
  @override
  bool operator ==(Object other) =>
      other is KategoriSampahModel && other.idKategori == idKategori;

  @override
  int get hashCode => idKategori.hashCode;
}