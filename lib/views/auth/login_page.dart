import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- TAMBAHKAN IMPORT INI
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart'; // <-- Pastikan path ApiService benar
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../main/main_navigation.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // FUNGSI BARU: AMBIL FCM TOKEN & KIRIM KE LARAVEL
  // ==========================================
  Future<void> _updateFcmToken() async {
    try {
      // 1. Minta izin notifikasi (Android 13+)
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Ambil token FCM
        String? token = await FirebaseMessaging.instance.getToken();
        
        if (token != null) {
          debugPrint('=== FCM TOKEN BERHASIL DIDAPAT ===');
          debugPrint(token);

          // 3. Kirim token ke Laravel
          final response = await ApiService.post(
            'update-fcm-token',
            body: jsonEncode({'fcm_token': token}),
          );

          if (response.statusCode == 200) {
            debugPrint('FCM Token berhasil dikirim ke Laravel');
          } else {
            debugPrint('Gagal mengirim token ke Laravel: ${response.body}');
          }
        }
      } else {
        debugPrint('Izin notifikasi ditolak pengguna');
      }
    } catch (e) {
      debugPrint('Gagal mendapatkan FCM Token: $e');
    }
  }

  // ==========================================
  // SUBMIT
  // ==========================================
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Backend menerima username ATAU email pada key 'username'.
    final result = await _authService.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final String token = result['token'];
      final UserModel user = result['user'];

      // Simpan token dan nama warga ke penyimpanan lokal (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString(
        'nama_warga',
        (user.profil?.nama ?? user.username).toUpperCase(),
      );
      
      // Simpan data rekening dan saldo dari profil API.
      final profil = user.profil;
      await prefs.setDouble('saldo_warga', profil?.saldo ?? 0.0);
      await prefs.setString(
        'nama_bank_ewallet',
        profil?.namaBankEwallet ?? '',
      );
      await prefs.setString(
        'nomor_rekening',
        profil?.nomorRekening ?? '',
      );
      await prefs.setString(
        'nama_pemilik_rekening',
        profil?.namaPemilikRekening ?? '',
      );
      await prefs.setString(
        'status_rekening',
        profil?.statusRekening ?? 'unverified',
      );

      debugPrint(
        'Login sukses: ${user.username}, ingat saya: $_rememberMe, token: $token',
      );

      // 👈 PANGGIL FUNGSI UPDATE FCM TOKEN DI SINI
      await _updateFcmToken();

      _showSnackBar('Login berhasil', isError: false);

      // Pindah ke kerangka utama (Beranda + navbar)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainNavigation(
            userName: (user.profil?.nama ?? user.username).toUpperCase(),
            tokenWarga: token,
          ),
        ),
        (route) => false,
      );
    } else {
      _showSnackBar(result['message'] ?? 'Login gagal', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================
  // UI
  // ==========================================
  Widget _buildCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _rememberMe = !_rememberMe),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _rememberMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _rememberMe ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: _rememberMe
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          const Text('Ingat saya', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const vPadding = 12.0 + 24.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - vPadding,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (Navigator.of(context).canPop())
                          IconButton(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            icon: const Icon(Icons.arrow_back, size: 26),
                            onPressed: () => Navigator.of(context).maybePop(),
                          )
                        else
                          const SizedBox(height: 48),
                        const Spacer(flex: 2),

                        Center(
                          child: Column(
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  'assets/images/login_avatar.png',
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 88,
                                    height: 88,
                                    color: const Color(0xFFD9D9D9),
                                    child: const Icon(
                                      Icons.person,
                                      size: 44,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Login Akun',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Mulai Ubah Sampah Jadi Rupiah',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.subtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        AppTextField(
                          label: 'Email',
                          hint: 'contoh@gmail.com...',
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          maxLength: 50,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Email wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        AppTextField(
                          label: 'Password',
                          hint: 'Password minimal 8...',
                          controller: _passwordController,
                          isPassword: true,
                          maxLength: 32,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            _buildCheckbox(),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                _showSnackBar(
                                  'Fitur lupa password belum tersedia',
                                  isError: true,
                                );
                              },
                              child: const Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        PrimaryButton(
                          text: 'Login',
                          isLoading: _isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 14),

                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Belum memiliki akun? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.subtitle,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                ),
                                child: const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}