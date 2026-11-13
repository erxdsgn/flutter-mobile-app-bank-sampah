import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../core/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _noHpController = TextEditingController();
  final _anggotaController = TextEditingController();
  final _emailController = TextEditingController();
  final _alamatController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _noHpController.dispose();
    _anggotaController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==========================================
  // SUBMIT
  // ==========================================
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Sesuaikan key dengan field yang divalidasi di endpoint /register-warga.
    final result = await _authService.register({
      'nama': _namaController.text.trim(),
      'nik': _nikController.text.trim(),
      'no_hp': _noHpController.text.trim(),
      'jumlah_anggota_keluarga': int.parse(_anggotaController.text.trim()),
      'email': _emailController.text.trim().toLowerCase(),
      'alamat': _alamatController.text.trim(),
      'password': _passwordController.text,
      // username tidak dikirim: dibuat otomatis oleh backend.
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final UserModel user = result['user'];
      debugPrint('Register sukses: ${user.username}');

      _showSnackBar(
        'Registrasi berhasil, silakan login',
        isError: false,
      );

      // Arahkan ke halaman login dan hapus halaman register dari stack,
      // sehingga tombol back tidak kembali ke form register.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else {
      _showSnackBar(result['message'] ?? 'Registrasi gagal', isError: true);
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tombol kembali
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(Icons.arrow_back, size: 26),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),

                // Header
                Center(
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          // Letakkan gambar di assets/images/ dan daftarkan
                          // di pubspec.yaml
                          'assets/images/register_avatar.png',
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
                      const SizedBox(height: 12),
                      const Text(
                        'Buat Akun',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Gabung menjadi nasabah bank sampah sahabat ibu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Nama Lengkap
                AppTextField(
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama anda...',
                  controller: _namaController,
                  keyboardType: TextInputType.name,
                  maxLength: 70,
                  inputFormatters: [
                    // Hanya huruf dan spasi (tanpa angka & simbol).
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                  validator: (v) {
                    final nama = (v ?? '').trim();
                    if (nama.isEmpty) return 'Nama wajib diisi';
                    if (nama.length < 3) return 'Nama minimal 3 huruf';
                    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(nama)) {
                      return 'Nama hanya boleh huruf';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // NIK
                AppTextField(
                  label: 'NIK',
                  hint: 'Nomor Induk Keluarga...',
                  controller: _nikController,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'NIK wajib diisi';
                    if (v.length != 16) return 'NIK harus 16 digit';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // WhatsApp (lebar) + Anggota Keluarga (sempit, input angka)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: AppTextField(
                        label: 'WhatsApp Aktif',
                        hint: '0812345...',
                        controller: _noHpController,
                        keyboardType: TextInputType.number,
                        maxLength: 14,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (v.length < 10) return 'Min. 10 digit';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        label: 'Anggota Keluarga',
                        hint: '1-10',
                        controller: _anggotaController,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          final n = int.tryParse(v);
                          if (n == null || n < 1 || n > 10) return '1-10';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Email
                AppTextField(
                  label: 'Email',
                  hint: 'contoh@gmail.com...',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 50,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  validator: (v) {
                    final email = (v ?? '').trim().toLowerCase();
                    if (email.isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[a-z0-9.+]+@gmail\.com$').hasMatch(email)) {
                      return 'Email harus menggunakan @gmail.com';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Alamat
                AppTextField(
                  label: 'Alamat',
                  hint: 'jl. letjen suprapto...',
                  controller: _alamatController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  maxLength: 200,
                  validator: (v) {
                    final alamat = (v ?? '').trim();
                    if (alamat.isEmpty) return 'Alamat wajib diisi';
                    if (alamat.length < 10) {
                      return 'Alamat minimal 10 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                AppTextField(
                  label: 'Password',
                  hint: 'Password minimal 8...',
                  controller: _passwordController,
                  isPassword: true,
                  maxLength: 32,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 8) return 'Password minimal 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Konfirmasi Password
                AppTextField(
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password anda...',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  maxLength: 32,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Konfirmasi password wajib diisi';
                    }
                    if (v != _passwordController.text) {
                      return 'Password tidak sama';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Tombol Daftar
                PrimaryButton(
                  text: 'Daftar',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 14),

                // Link ke Login
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sudah memiliki akun? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.subtitle,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Text(
                          'Login',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}