import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_app_bar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_dropdown_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton_box.dart'; // Import skeleton

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditMode = false;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controller untuk Mode Edit
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _waController = TextEditingController();
  final _alamatController = TextEditingController();
  final _nomorRekeningController = TextEditingController();
  final _namaPemilikRekeningController = TextEditingController();
  final _anggotaController = TextEditingController();

  String? _selectedKelompok;
  final List<String> _kelompokList = ["A (Perumahan)", "B (Luar Perumahan)"];

  // Variabel untuk menyimpan data saat Mode Lihat (Read-Only)
  String _viewNama = '-';
  String _viewUsername = '-';
  String _viewEmail = '-';
  String _viewWa = '-';
  String _viewAlamat = '-';
  String _viewKelompok = '-';
  String _viewAnggota = '-';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _waController.dispose();
    _alamatController.dispose();
    _nomorRekeningController.dispose();
    _namaPemilikRekeningController.dispose();
    _anggotaController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await ApiService.get('me');
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['data'];
        final profil = user['profil'];

        setState(() {
          // Isi Controller untuk Form
          _namaController.text = profil['nama'] ?? '';
          _usernameController.text = user['username'] ?? '';
          _emailController.text = user['email'] ?? '';
          _waController.text = profil['no_hp'] ?? '';
          _alamatController.text = profil['alamat'] ?? '';
          _nomorRekeningController.text = profil['nomor_rekening'] ?? '';
          _namaPemilikRekeningController.text =
              profil['nama_pemilik_rekening'] ?? '';
          _anggotaController.text =
              profil['jumlah_anggota_keluarga']?.toString() ?? '1';

          final kelompokApi = profil['kelompok'];
          if (kelompokApi != null && _kelompokList.contains(kelompokApi)) {
            _selectedKelompok = kelompokApi;
          }

          // Isi Variabel untuk Tampilan Read-Only
          _viewNama = profil['nama'] ?? '-';
          _viewUsername = user['username'] ?? '-';
          _viewEmail = user['email'] ?? '-';
          _viewWa = profil['no_hp'] ?? '-';
          _viewAlamat = profil['alamat'] ?? '-';
          _viewKelompok = _selectedKelompok ?? 'Belum dipilih';
          _viewAnggota = "${profil['jumlah_anggota_keluarga'] ?? 1} Orang";

          _isLoading = false;
        });
      } else {
        _fallbackToPrefs();
      }
    } catch (e) {
      _fallbackToPrefs();
    }
  }

  Future<void> _fallbackToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _namaController.text = prefs.getString('nama_warga') ?? '';
      _usernameController.text = prefs.getString('username') ?? '';
      
      _viewNama = prefs.getString('nama_warga') ?? '-';
      _viewUsername = prefs.getString('username') ?? '-';

      _isLoading = false;
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final bodyData = {
        'username': _usernameController.text.trim(),
        'nama': _namaController.text.trim(),
        'kelompok': _selectedKelompok,
        'no_hp': _waController.text.trim(),
        'jumlah_anggota_keluarga': int.tryParse(_anggotaController.text.trim()) ?? 1,
        'alamat': _alamatController.text.trim(),
        'nomor_rekening': _nomorRekeningController.text.trim(),
        'nama_pemilik_rekening': _namaPemilikRekeningController.text.trim(),
      };

      final response = await ApiService.put(
        'update-profile',
        body: jsonEncode(bodyData),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);
      setState(() => _isSaving = false);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'nama_warga',
          _namaController.text.trim().toUpperCase(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil berhasil diperbarui!"),
            backgroundColor: AppColors.primary,
          ),
        );
        
        _fetchUserData(); 
        setState(() {
          _isEditMode = false;
        });
        
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal memperbarui profil'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Koneksi error: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // Widget Bantuan untuk Mode Read-Only agar lebih rapi
  Widget _buildInfoCard(String label, String value, {int maxLines = 1}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- WIDGET SKELETON UNTUK HALAMAN INI ---
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonCard(),
          _buildSkeletonCard(),
          Row(
            children: [
              Expanded(child: _buildSkeletonCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonCard()),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildSkeletonCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonCard()),
            ],
          ),
          _buildSkeletonCard(height: 80), // Untuk alamat yang lebih panjang
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({double height = 60}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 100, height: 12), // Label
          const SizedBox(height: 8),
          SkeletonBox(width: double.infinity, height: height * 0.35), // Isi Data
        ],
      ),
    );
  }
  // -----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimaryAppBar(
        title: "Informasi Pribadi",
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _toggleEdit,
              child: Text(
                _isEditMode ? "Batal" : "Edit",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      // MENGUBAH SPINNER MENJADI SKELETON
      body: _isLoading
          ? _buildSkeleton()
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _isEditMode
                    ? Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: "Nama Lengkap",
                              hint: "Masukkan nama lengkap...",
                              controller: _namaController,
                              validator: (v) => v == null || v.isEmpty
                                  ? "Nama wajib diisi"
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: "Nama Pengguna (Username)",
                              hint: "Masukkan username...",
                              controller: _usernameController,
                              validator: (v) => v == null || v.isEmpty
                                  ? "Username wajib diisi"
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: "Email",
                                    hint: "Email aktif...",
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    label: "Nomor WhatsApp",
                                    hint: "0812345...",
                                    controller: _waController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppDropdownField<String>(
                                    label: "Kelompok",
                                    hint: "Pilih",
                                    value: _selectedKelompok,
                                    items: _kelompokList,
                                    onChanged: (val) {
                                      setState(() => _selectedKelompok = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    label: "Anggota Keluarga",
                                    hint: "Cth: 4",
                                    controller: _anggotaController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: "Alamat Lengkap",
                              hint: "Jalan, Perumahan, RT/RW...",
                              controller: _alamatController,
                              maxLines: 2,
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 24),
                            PrimaryButton(
                              text: "Simpan Perubahan",
                              isLoading: _isSaving,
                              onPressed: _saveChanges,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard("Nama Lengkap", _viewNama),
                          _buildInfoCard("Nama Pengguna (Username)", _viewUsername),
                          Row(
                            children: [
                              Expanded(child: _buildInfoCard("Email", _viewEmail)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildInfoCard("Nomor WhatsApp", _viewWa)),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: _buildInfoCard("Kelompok", _viewKelompok)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildInfoCard("Anggota Keluarga", _viewAnggota)),
                            ],
                          ),
                          _buildInfoCard("Alamat Lengkap", _viewAlamat, maxLines: 3),
                        ],
                      ),
              ),
            ),
    );
  }
}