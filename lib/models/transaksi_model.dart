double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class TransaksiItemModel {
  final String namaKategori;
  final double jumlah;
  final String satuan;
  final double hargaSatuan;
  final double subtotal;

  TransaksiItemModel({
    required this.namaKategori,
    required this.jumlah,
    required this.satuan,
    required this.hargaSatuan,
    required this.subtotal,
  });

  factory TransaksiItemModel.fromJson(Map<String, dynamic> json) {
    // Membaca nama kategori langsung atau dari objek relasi 'kategori'
    final namaKat = json['nama_kategori'] ?? 
                    json['kategori']?['nama_kategori'] ?? 
                    '';

    final satuanKat = json['satuan'] ?? 
                      json['kategori']?['satuan'] ?? 
                      'kg';

    return TransaksiItemModel(
      namaKategori: namaKat.toString(),
      jumlah: _toDouble(json['jumlah']),
      satuan: satuanKat.toString(),
      hargaSatuan: _toDouble(json['harga_satuan'] ?? json['harga_per_gram']),
      subtotal: _toDouble(json['subtotal']),
    );
  }
}

class TransaksiModel {
  final int id;
  final String nomorBukti;
  final String tanggal;
  final String namaNasabah;
  final String status;
  final double totalNilai;
  final String? catatanAdmin;
  final List<TransaksiItemModel> items;

  TransaksiModel({
    required this.id,
    required this.nomorBukti,
    required this.tanggal,
    required this.namaNasabah,
    required this.status,
    required this.totalNilai,
    this.catatanAdmin,
    required this.items,
  });

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    // Menyesuaikan key 'details' dari Laravel atau 'items'
    final rawItems = (json['details'] ?? json['items']) as List<dynamic>?;

    return TransaksiModel(
      id: _toInt(json['id_setoran'] ?? json['id']),
      nomorBukti: (json['kode_transaksi'] ?? json['nomor_bukti'])?.toString() ?? '',
      tanggal: (json['tanggal_setoran'] ?? json['tanggal'])?.toString() ?? '',
      namaNasabah: (json['nama_nasabah'] ?? json['warga']?['nama'] ?? json['id_warga'])?.toString() ?? '',
      status: json['status']?.toString() ?? 'Proses',
      totalNilai: _toDouble(json['total_nilai']),
      catatanAdmin: json['catatan_admin']?.toString(),
      items: rawItems?.map((e) => TransaksiItemModel.fromJson(e)).toList() ?? [],
    );
  }
}