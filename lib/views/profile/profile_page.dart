import 'dart:convert';
import 'package:bank_sampah/views/profile/about_page.dart';
import 'package:bank_sampah/views/profile/pusat_bantuan_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_app_bar.dart';
import '../../widgets/skeleton_box.dart';
import '../auth/login_page.dart';
import 'bank_account_page.dart'; // <-- IMPORT HALAMAN REKENING BANK
import 'change_password_page.dart';
import 'personal_info_page.dart';
import '../../core/helpers/transaction_helpers.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String _username = '';
  String? _avatarUrl;
  bool _notifikasiAktif = true; // State untuk Switch Notifikasi

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // --- MENGAMBIL DATA DARI CACHE & API ---
  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('nama_warga');
      final cachedAvatar = prefs.getString('avatar_url');

      try {
        final response = await ApiService.get('me');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'];
          final freshAvatar = data['avatar_url'] as String?;
          final freshName = data['profil']?['nama'] as String?;
          
          // Ambil status notifikasi dari API
          final isNotifAktif = data['notifikasi_aktif'] ?? true;
          _notifikasiAktif = isNotifAktif == true || isNotifAktif == 1;

          if (freshAvatar != null && freshAvatar.isNotEmpty) {
            final fixedAvatar = freshAvatar
                .replaceAll('127.0.0.1', '10.0.2.2')
                .replaceAll('localhost', '10.0.2.2');
            await prefs.setString('avatar_url', fixedAvatar);
          } else {
            await prefs.remove('avatar_url');
          }
          if (freshName != null && freshName.isNotEmpty) {
            await prefs.setString('nama_warga', freshName.toUpperCase());
          }
        }
      } catch (e) {
        debugPrint('Error saat load /me: $e');
      }

      final updatedPrefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _username = updatedPrefs.getString('nama_warga') ?? cachedName ?? 'WARGA BANK SAMPAH';
        _avatarUrl = updatedPrefs.getString('avatar_url') ?? cachedAvatar;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI TOGGLE NOTIFIKASI ---
  Future<void> _toggleNotifikasi(bool value) async {
    setState(() => _notifikasiAktif = value);

    try {
      final response = await ApiService.put(
        'update-notifikasi',
        body: jsonEncode({'notifikasi_aktif': value}),
      );

      if (response.statusCode != 200) {
        setState(() => _notifikasiAktif = !value);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan pengaturan notifikasi'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      setState(() => _notifikasiAktif = !value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Koneksi error: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // --- FUNGSI INISIAL NAMA ---
  String _getInitials(String name) {
    if (name.isEmpty || name == 'WARGA BANK SAMPAH') return 'W';
    
    final words = name.trim().split(RegExp(r'\s+'));
    
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0].length >= 2 
          ? words[0].substring(0, 2).toUpperCase() 
          : words[0][0].toUpperCase();
    }
    return 'W';
  }

  // --- FUNGSI PILIH FOTO & UPLOAD ---
  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final uri = Uri.parse('${ApiService.baseUrl}/update-avatar');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.files.add(await http.MultipartFile.fromPath('avatar', image.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawAvatarUrl = data['avatar_url'];

        final newAvatarUrl = rawAvatarUrl != null 
            ? rawAvatarUrl.toString()
                .replaceAll('127.0.0.1', '10.0.2.2')
                .replaceAll('localhost', '10.0.2.2')
            : null;

        if (newAvatarUrl != null) {
          await prefs.setString('avatar_url', newAvatarUrl);
        }

        setState(() {
          _avatarUrl = newAvatarUrl;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto profil berhasil diperbarui!"),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mengunggah foto profil"),
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

  // --- DIALOG PILIH SUMBER FOTO ---
  void _showAvatarSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Foto Profil",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Kamera",
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadAvatar(ImageSource.camera);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: "Galeri",
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadAvatar(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PrimaryAppBar(
        title: "Profile",
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? _buildSkeleton()
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 30),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        
                        // --- BAGIAN AVATAR ---
                        Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.white, width: 3),
                                image: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          _avatarUrl!.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2'),
                                        ),
                                        fit: BoxFit.cover,
                                        onError: (exception, stackTrace) {
                                          debugPrint('Gagal memuat gambar: $exception');
                                        },
                                      )
                                    : null,
                              ),
                              child: _avatarUrl == null || _avatarUrl!.isEmpty
                                  ? Center(
                                      child: Text(
                                        _getInitials(_username),
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showAvatarSourceDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryDark,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            formatNamaRingkas(_username, maxCharLimit: 26),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        const Text(
                          "Nasabah Bank Sampah Sahabat Ibu",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Akun",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.muted),
                        ),
                        const SizedBox(height: 8),
                        
                        _MenuCard(
                          icon: Icons.person_outline,
                          title: "Informasi Pribadi",
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
                            );
                            if (result == true) {
                              _loadProfileData();
                            }
                          },
                        ),

                        // --- MENU BARU: REKENING BANK ---
                        _MenuCard(
                          icon: Icons.account_balance_outlined,
                          title: "Rekening Bank & E-Wallet",
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BankAccountPage(),
                              ),
                            );
                            if (result == true) {
                              _loadProfileData();
                            }
                          },
                        ),
                        
                        _MenuCard(
                          icon: Icons.lock_outline,
                          title: "Password",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordPage(),
                              ),
                            );
                          },
                        ),
                        
                        // --- TOGGLE NOTIFIKASI ---
                        _MenuCard(
                          icon: Icons.notifications_none,
                          title: "Notifikasi",
                          trailing: Switch(
                            value: _notifikasiAktif,
                            onChanged: _toggleNotifikasi,
                            activeColor: AppColors.primary,
                          ),
                          onTap: () {
                            _toggleNotifikasi(!_notifikasiAktif);
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        const Text(
                          "Preferensi",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.muted),
                        ),
                        const SizedBox(height: 8),
                        
                        _MenuCard(
                          icon: Icons.info_outline,
                          title: "Tentang Kami",
                          onTap: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AboutPage(),
                              ),
                            );
                          },
                        ),
                        
                        _MenuCard(
                          icon: Icons.help_outline,
                          title: "Bantuan",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PusatBantuanPage(),
                              ),
                            );
                          },
                        ),
                        
                        _MenuCard(
                          icon: Icons.logout,
                          title: "Keluar",
                          titleColor: AppColors.danger,
                          iconColor: AppColors.danger,
                          onTap: () {
                            _showLogoutDialog(context);
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30, top: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SkeletonBox(width: 90, height: 90, borderRadius: 45),
                const SizedBox(height: 12),
                const SkeletonBox(width: 150, height: 20),
                const SizedBox(height: 8),
                SkeletonBox(width: 200, height: 14, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 50, height: 14),
                const SizedBox(height: 12),
                _buildSkeletonMenu(),
                _buildSkeletonMenu(),
                _buildSkeletonMenu(),
                _buildSkeletonMenu(),
                const SizedBox(height: 20),
                const SkeletonBox(width: 70, height: 14),
                const SizedBox(height: 12),
                _buildSkeletonMenu(),
                _buildSkeletonMenu(),
                _buildSkeletonMenu(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonMenu() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 22, height: 22, borderRadius: 4),
          const SizedBox(width: 16),
          const Expanded(child: SkeletonBox(width: double.infinity, height: 16)),
          const SizedBox(width: 16),
          const SkeletonBox(width: 20, height: 20, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _MenuCard({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? AppColors.textDark, size: 22),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, color: titleColor ?? AppColors.textDark),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Konfirmasi Logout",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar?",
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (!context.mounted) return;
              Navigator.pop(context);

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}