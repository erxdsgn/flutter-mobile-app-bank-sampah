// lib/models/trash_price_model.dart
class TrashPrice {
  final int idKategori;
  final String namaKategori;
  final String satuan;
  final double hargaSatuan;
  final String tanggalBerlaku;

  TrashPrice({
    required this.idKategori,
    required this.namaKategori,
    required this.satuan,
    required this.hargaSatuan,
    required this.tanggalBerlaku,
  });

  factory TrashPrice.fromJson(Map<String, dynamic> json) {
    // 1. Fallback nama key untuk ID, Nama, dan Satuan
    final id = json['id_kategori'] ?? json['id'] ?? 0;
    final nama = json['nama_kategori'] ?? json['nama'] ?? json['name'] ?? '';
    final unit = json['satuan'] ?? json['unit'] ?? 'kg';

    // 2. Parsing Harga (Mendukung tipe num, string, dan angka berformat)
    final rawHarga = json['harga_satuan'] ?? json['harga'] ?? json['nominal'] ?? json['price'] ?? 0;
    double parsedHarga = 0.0;

    if (rawHarga is num) {
      parsedHarga = rawHarga.toDouble();
    } else if (rawHarga is String) {
      String cleanStr = rawHarga.trim().replaceAll('Rp', '').replaceAll(' ', '');
      if (cleanStr.contains('.') && cleanStr.contains(',')) {
        cleanStr = cleanStr.replaceAll('.', '').replaceAll(',', '.');
      } else if (cleanStr.contains('.')) {
        List<String> parts = cleanStr.split('.');
        if (parts.last.length == 3) {
          cleanStr = cleanStr.replaceAll('.', '');
        }
      } else if (cleanStr.contains(',')) {
        cleanStr = cleanStr.replaceAll(',', '.');
      }
      parsedHarga = double.tryParse(cleanStr) ?? 0.0;
    }

    // 3. Parsing Format Tanggal
    String rawDate = (json['tanggal_berlaku'] ?? json['updated_at'] ?? json['created_at'] ?? '').toString();
    String formattedDate = '-';

    if (rawDate.isNotEmpty && rawDate != '-') {
      try {
        DateTime parsedDate = DateTime.parse(rawDate);
        String day = parsedDate.day.toString().padLeft(2, '0');
        String year = parsedDate.year.toString();
        const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
        formattedDate = "$day ${months[parsedDate.month]} $year";
      } catch (_) {
        if (rawDate.length >= 10) {
          String datePart = rawDate.substring(0, 10);
          List<String> parts = datePart.split('-');
          if (parts.length == 3) {
            formattedDate = "${parts[2]}-${parts[1]}-${parts[0]}";
          }
        }
      }
    }

    return TrashPrice(
      idKategori: id is int ? id : int.tryParse(id.toString()) ?? 0,
      namaKategori: nama.toString(),
      satuan: unit.toString(),
      hargaSatuan: parsedHarga,
      tanggalBerlaku: formattedDate,
    );
  }

  // Helper Format Rupiah
  String get formattedPrice {
    final integer = hargaSatuan.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $integer';
  }
}