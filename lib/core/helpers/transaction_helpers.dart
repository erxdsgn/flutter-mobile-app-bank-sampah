import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../../models/transaksi_model.dart';

// ======================================================
// STATUS SETORAN
// ======================================================

enum StatusSetoran { menunggu, diterima, ditolak }

/// Memetakan teks status dari backend ke enum.
/// Sesuaikan kata kuncinya kalau backend memakai istilah lain.
StatusSetoran statusSetoranFrom(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('tolak')) return StatusSetoran.ditolak;
  if (s.contains('proses') ||
      s.contains('menunggu') ||
      s.contains('pending')) {
    return StatusSetoran.menunggu;
  }
  return StatusSetoran.diterima;
}

extension StatusSetoranX on StatusSetoran {
  String get label {
    switch (this) {
      case StatusSetoran.menunggu:
        return 'Menunggu';
      case StatusSetoran.diterima:
        return 'Diterima';
      case StatusSetoran.ditolak:
        return 'Ditolak';
    }
  }

  Color get color {
    switch (this) {
      case StatusSetoran.menunggu:
        // Menggunakan warna peringatan/oranye yang senada
        return const Color(0xFFE59A0B);
      case StatusSetoran.diterima:
        return AppColors.primary; // Mengambil dari AppColors
      case StatusSetoran.ditolak:
        return AppColors.danger;  // Mengambil dari AppColors yang baru ditambahkan
    }
  }

  Color get softColor {
    switch (this) {
      case StatusSetoran.menunggu:
        return const Color(0xFFFFF4DB);
      case StatusSetoran.diterima:
        return AppColors.primaryLight; // Mengambil dari AppColors
      case StatusSetoran.ditolak:
        return const Color(0xFFFDE8E8);
    }
  }

  IconData get icon {
    switch (this) {
      case StatusSetoran.menunggu:
        return Icons.hourglass_top_rounded;
      case StatusSetoran.diterima:
        return Icons.recycling_rounded;
      case StatusSetoran.ditolak:
        return Icons.close_rounded;
    }
  }
}

/// Label kecil berwarna: Menunggu (kuning), Diterima (hijau), Ditolak (merah).
class StatusChip extends StatelessWidget {
  final StatusSetoran status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// FORMATTER
// ======================================================

String formatRupiah(double value) {
  final integer = value.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp$integer';
}

const List<String> _namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// "2026-10-13" atau "2026-10-13T08:00:00Z" -> "13 Oktober 2026".
/// Kalau format tidak dikenali, teks asli ditampilkan apa adanya.
String formatTanggal(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw.isEmpty ? '-' : raw;
  final d = parsed.isUtc ? parsed.toLocal() : parsed;
  return '${d.day} ${_namaBulan[d.month - 1]} ${d.year}';
}

/// 2.5 -> "2.5", 4.0 -> "4.0", 1.25 -> "1.25"
String formatJumlah(double value) {
  final oneDecimal = (value * 10).roundToDouble() == value * 10;
  return value.toStringAsFixed(oneDecimal ? 1 : 2);
}

/// "Setor Plastik" atau "Setor Plastik +2 lainnya"
String judulSetoran(TransaksiModel trx) {
  if (trx.items.isEmpty) return 'Setor Sampah';
  final first = trx.items.first.namaKategori;
  final extra = trx.items.length - 1;
  return extra > 0 ? 'Setor $first +$extra lainnya' : 'Setor $first';
}

/// Menyingkat nama secara cerdas agar pas di struk dan kartu transaksi.
/// Contoh: "Erix Agung Wibowo" -> "Erix Agung W."
String formatNamaRingkas(String name, {int maxCharLimit = 16}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '-';

  // Jika total panjang nama sudah muat, tampilkan utuh semuanya
  if (trimmed.length <= maxCharLimit) return trimmed;

  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length <= 1) return trimmed;

  final List<String> resultParts = [];
  int currentLength = 0;
  bool startAbbreviating = false;

  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    if (word.isEmpty) continue;

    // Kata pertama SELALU ditulis utuh
    if (i == 0) {
      resultParts.add(word);
      currentLength += word.length;
      continue;
    }

    // Perkiraan total panjang jika kata ini dimasukkan utuh
    final remainingWordsCount = words.length - 1 - i;
    final estimatedLengthIfFull =
        currentLength + 1 + word.length + (remainingWordsCount * 3);

    // Jika belum harus disingkat dan masih muat dalam batas limit
    if (!startAbbreviating && estimatedLengthIfFull <= maxCharLimit) {
      resultParts.add(word);
      currentLength += 1 + word.length;
    } else {
      // Jika tidak muat, ubah kata ini dan seterusnya menjadi inisial
      startAbbreviating = true;
      resultParts.add('${word[0].toUpperCase()}.');
      currentLength += 3;
    }
  }

  return resultParts.join(' ');
}