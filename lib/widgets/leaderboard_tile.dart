import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/leaderboard_model.dart';

class LeaderboardTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;

  const LeaderboardTile({
    super.key,
    required this.rank,
    required this.entry,
  });

  /// Helper untuk menyingkat nama panjang agar tidak terpotong kasar (...)
  /// Contoh: "Erix Agung Wibowo" -> "Erix Agung W."
  String _formatNamaRingkas(String name, {int maxCharLimit = 16}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '-';
    if (trimmed.length <= maxCharLimit) return trimmed;

    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= 1) return trimmed;

    final List<String> resultParts = [];
    int currentLength = 0;
    bool startAbbreviating = false;

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      if (i == 0) {
        resultParts.add(word);
        currentLength += word.length;
        continue;
      }

      final remainingWordsCount = words.length - 1 - i;
      final estimatedLengthIfFull =
          currentLength + 1 + word.length + (remainingWordsCount * 3);

      if (!startAbbreviating && estimatedLengthIfFull <= maxCharLimit) {
        resultParts.add(word);
        currentLength += 1 + word.length;
      } else {
        startAbbreviating = true;
        resultParts.add('${word[0].toUpperCase()}.');
        currentLength += 3;
      }
    }

    return resultParts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // 1. Nomor Peringkat
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Avatar Lingkaran Hijau Muda dengan Inisial
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFD4EDDA),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              entry.initials,
              style: const TextStyle(
                color: Color(0xFF155724),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // 3. Nama Warga Ringkas & Subteks Frekuensi Setor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatNamaRingkas(entry.nama, maxCharLimit: 18),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.totalSetor > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${entry.totalSetor}x setor',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 4. Total Poin / Berat di Sebelah Kanan
          Text(
            '${entry.totalPoints} P',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}