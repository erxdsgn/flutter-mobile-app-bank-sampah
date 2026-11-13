import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  Future<List<LeaderboardEntry>> fetchSeasonIni() async {
    try {
      final response = await ApiService.get(
        'leaderboard?periode=season_ini',
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil data leaderboard');
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> listData = responseData['data'] ?? [];

      final prefs = await SharedPreferences.getInstance();
      String? currentUserId = prefs.getString('id_warga');

      debugPrint('=== DEBUG LEADERBOARD ===');
      debugPrint('Current User ID dari SharedPreferences: $currentUserId');

      return listData.map((item) {
        final entry = LeaderboardEntry.fromJson(
          item,
          currentUserId: currentUserId,
        );
        if (entry.isCurrentUser) {
          debugPrint('COCOK! User aktif ditemukan pada Peringkat #${entry.rank} (${entry.nama})');
        }
        return entry;
      }).toList();
    } catch (e) {
      debugPrint('Error Leaderboard: $e');
      throw Exception('Gagal memuat papan peringkat: $e');
    }
  }
}