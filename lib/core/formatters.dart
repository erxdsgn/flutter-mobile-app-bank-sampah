/// Helper format tampilan. Ditulis manual (tanpa package intl) sehingga tidak
/// perlu initializeDateFormatting('id_ID') di main.dart.
class Formatters {
  Formatters._();

  static const List<String> _bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// 21000 -> "Rp21.000"
  static String rupiah(double value) {
    final n = value.round();
    final digits = n.abs().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
        );
    return '${n < 0 ? '-' : ''}Rp$digits';
  }

  /// DateTime -> "07 Agustus 2026"
  static String tanggal(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_bulan[d.month - 1]} ${d.year}';

  /// 3.0 -> "3", 2.5 -> "2,5", 2.255 -> "2,26" (maks. 2 desimal)
  static String angka(double value) {
    final r = double.parse(value.toStringAsFixed(2));
    if (r % 1 == 0) return r.toInt().toString();
    return r.toString().replaceAll('.', ',');
  }

  /// (3, 'kg') -> "3kg", (1, 'unit') -> "1 unit"
  static String jumlah(double value, String satuan) {
    final s = satuan.trim();
    final rapat = s.toLowerCase() == 'kg' || s.toLowerCase() == 'g';
    return rapat ? '${angka(value)}$s' : '${angka(value)} $s';
  }

  /// Membaca angka dari input pengguna; koma dianggap titik desimal.
  static double? parseAngka(String? text) {
    if (text == null) return null;
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}