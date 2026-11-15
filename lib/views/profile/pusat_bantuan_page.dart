import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class PusatBantuanPage extends StatelessWidget {
  const PusatBantuanPage({super.key});

  // Fungsi untuk membuka link
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak bisa membuka link: $url');
    }
  }

  // Fungsi untuk menampilkan Bottom Sheet Jam Kerja
  void _showWorkingHours(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar kecil di atas
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                "Waktu Operasional",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),

              // Item Telepon
              _InfoRow(
                icon: Icons.phone_in_talk_outlined,
                title: "Telepon",
                subtitle: "Setiap hari: 24/7",
              ),
              const SizedBox(height: 16),
              
              // Item Email
              _InfoRow(
                icon: Icons.mark_email_unread_outlined,
                title: "Kirim e-mail",
                subtitle: "Setiap hari: 24/7",
              ),
              
              const SizedBox(height: 32),

              // Tombol Oke
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green, // Warna Oranye Jago
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Oke",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            //header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Tanya Gemi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

           
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Ilustrasi Toa (Megaphone)
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Color(0xFFEEF6F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.campaign,
                          size: 80,
                          color:Color(0xFF45DD60),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Judul & Deskripsi
                    const Text(
                      "Tanya Gemi",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Hubungi Tanya Gemi untuk bantuan masalah atau berikan masukan. Kami menghargai setiap masukan.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    //hubungi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Hubungi Kami",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        // Tombol Jam Kerja
                        InkWell(
                          onTap: () => _showWorkingHours(context),
                          child: const Text(
                            "Jam Kerja",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF45DD60),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),

                    // Tiga Tombol Aksi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ActionButton(
                          icon: Icons.phone_in_talk_outlined,
                          label: "Telepon",
                          onTap: () => _launchURL("tel:+6282141055878"),
                        ),
                        _ActionButton(
                          icon: Icons.mark_email_unread_outlined,
                          label: "Kirim e-mail",
                          onTap: () => _launchURL("mailto:BSSkontact@gmail.com"),
                        ),
                        _ActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: "Chat kami",
                          onTap: () => _launchURL("https://wa.me/6282141055878"),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Menu Footer (Tentang Gemi)
                    Row(
                      children: [
                        const Icon(Icons.support_agent, color: Color(0xFF45DD60)),
                        const SizedBox(width: 12),
                        const Text(
                          "Tentang Gemi",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget bantuan untuk tombol aksi (Telepon, Email, Chat)
  Widget _ActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color:Color(0xFF45DD60), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget bantuan untuk baris info di Bottom Sheet
  Widget _InfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xFFEEF6F1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color:Color(0xFF45DD60), size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}