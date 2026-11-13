import 'package:flutter/material.dart';
import '../../models/leaderboard_model.dart';

class Podium extends StatelessWidget {
  final LeaderboardEntry first;
  final LeaderboardEntry second;
  final LeaderboardEntry third;

  const Podium({
    super.key,
    required this.first,
    required this.second,
    required this.third,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Juara 2 (Kiri - Silver)
          Expanded(
            child: _PodiumColumn(
              entry: second,
              rank: 2,
              podiumHeight: 65,
              podiumColor: const LinearGradient(
                colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              avatarSize: 56,
            ),
          ),
          const SizedBox(width: 8),

          // Juara 1 (Tengah - Emas)
          Expanded(
            child: _PodiumColumn(
              entry: first,
              rank: 1,
              podiumHeight: 90,
              podiumColor: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              avatarSize: 66,
              hasCrown: true,
            ),
          ),
          const SizedBox(width: 8),

          // Juara 3 (Kanan - Perunggu)
          Expanded(
            child: _PodiumColumn(
              entry: third,
              rank: 3,
              podiumHeight: 50,
              podiumColor: const LinearGradient(
                colors: [Color(0xFFD7CCC8), Color(0xFFA1887F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              avatarSize: 56,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double podiumHeight;
  final Gradient podiumColor;
  final double avatarSize;
  final bool hasCrown;

  const _PodiumColumn({
    required this.entry,
    required this.rank,
    required this.podiumHeight,
    required this.podiumColor,
    required this.avatarSize,
    this.hasCrown = false,
  });

  /// Helper untuk menyingkat nama panjang (Limit diperbesar menjadi 18 karakter)
  String _formatNamaRingkas(String name, {int maxCharLimit = 18}) {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Piala Emas untuk Juara 1
        if (hasCrown)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Icon(
              Icons.emoji_events,
              size: 24,
              color: Color(0xFFFFC107),
            ),
          )
        else
          const SizedBox(height: 26),

        // Avatar Inisial Lingkaran
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8F5E9),
            border: Border.all(
              color: hasCrown ? const Color(0xFFFFB300) : Colors.grey.shade400,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            entry.initials,
            style: TextStyle(
              color: const Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
              fontSize: avatarSize * 0.35,
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Nama Warga Ringkas (Limit 18 Karakter)
        Text(
          _formatNamaRingkas(entry.nama, maxCharLimit: 16),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 1),

        // Total Poin
        Text(
          '${entry.totalPoints} P',
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        // Balok Podium di Bawah
        Container(
          height: podiumHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: podiumColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}