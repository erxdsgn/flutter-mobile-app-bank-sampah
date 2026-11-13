import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../services/api_service.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/primary_button.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    FocusScope.of(context).unfocus();
    
    // 1. Validasi input di sisi Flutter
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 2. Siapkan data untuk dikirim ke Laravel
      final bodyData = {
        'current_password': _currentPasswordController.text,
        'new_password': _newPasswordController.text,
        'new_password_confirmation': _confirmPasswordController.text, // Wajib untuk validasi 'confirmed' di Laravel
      };

      // 3. Tembak API Laravel
      final response = await ApiService.post(
        'change-password', 
        body: jsonEncode(bodyData),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final data = jsonDecode(response.body);

      // 4. Cek respon dari server
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Password berhasil diperbarui!"),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context); 
      } else {
        // Jika password lama salah atau validasi Laravel gagal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal mengubah password'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Koneksi error: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PrimaryAppBar(
        title: "Ubah Password",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Password Saat Ini
                AppTextField(
                  label: "Password Saat Ini",
                  hint: "Masukkan password saat ini",
                  controller: _currentPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password tidak boleh kosong";
                    }
                    return null; 
                  },
                ),
                const SizedBox(height: 16),

                // Input Password Baru
                AppTextField(
                  label: "Password Baru",
                  hint: "Masukkan password baru",
                  controller: _newPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password baru tidak boleh kosong";
                    }
                    if (value.length < 8) {
                      return "Password minimal 8 karakter";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Input Konfirmasi Password
                AppTextField(
                  label: "Konfirmasi Password Baru",
                  hint: "Ulangi password baru",
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Konfirmasi tidak boleh kosong";
                    }
                    if (value != _newPasswordController.text) {
                      return "Konfirmasi password tidak cocok";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Tombol Update
                PrimaryButton(
                  text: "Ubah Password",
                  isLoading: _isLoading,
                  onPressed: _submitUpdate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}