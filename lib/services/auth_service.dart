import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await ApiService.post(
        'login',
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final responseData = data['data'];
        final token = responseData['token'];
        final userJson = responseData['user'];

        // AMBIL id_warga DARI userJson['profil'] (Sesuai struktur response Laravel)
        final idWarga =
            userJson['profil']?['id_warga']?.toString() ??
            userJson['id_warga']?.toString() ??
            userJson['warga']?['id_warga']?.toString();

        debugPrint('=== DEBUG LOGIN ===');
        debugPrint('Token: $token');
        debugPrint('ID Warga yang didapat dari API: $idWarga');

        // SIMPAN KE SHARED PREFERENCES
        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString('auth_token', token);
        }
        if (idWarga != null) {
          await prefs.setString('id_warga', idWarga);
          debugPrint(
            'ID Warga berhasil disimpan ke SharedPreferences: $idWarga',
          );
        } else {
          debugPrint('PERINGATAN: id_warga bernilai NULL saat login!');
        }

        // Buat UserModel terlebih dahulu
        final userModel = UserModel.fromJson(userJson);

        // Simpan avatar_url dari UserModel jika ada
        if (userModel.avatarUrl != null && userModel.avatarUrl!.isNotEmpty) {
          await prefs.setString('avatar_url', userModel.avatarUrl!);
        } else {
          await prefs.remove('avatar_url');
        }

        return {'success': true, 'token': token, 'user': userModel};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      debugPrint('Error Login Exception: $e');
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(
    Map<String, dynamic> registerData,
  ) async {
    try {
      final response = await ApiService.post(
        'register-warga',
        body: jsonEncode(registerData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final responseData = data['data'];
        final token = responseData['token'];
        final userJson = responseData['user'];

        // Ambil id_warga dari profil saat register
        final idWarga =
            userJson['profil']?['id_warga']?.toString() ??
            userJson['id_warga']?.toString() ??
            responseData['warga']?['id_warga']?.toString();

        final prefs = await SharedPreferences.getInstance();
        if (token != null) await prefs.setString('auth_token', token);
        if (idWarga != null) await prefs.setString('id_warga', idWarga);

        final userModel = UserModel.fromJson(userJson);

        if (userModel.avatarUrl != null && userModel.avatarUrl!.isNotEmpty) {
          await prefs.setString('avatar_url', userModel.avatarUrl!);
        } else {
          await prefs.remove('avatar_url');
        }

        return {
          'success': true,
          'message': data['message'],
          'token': token,
          'user': userModel,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registrasi gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }
}
