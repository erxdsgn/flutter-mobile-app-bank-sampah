import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_colors.dart';
import '../../../../widgets/primary_app_bar.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  // Fungsi untuk membuka link
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak bisa membuka link: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PrimaryAppBar(title: "Pusat Bantuan"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Ilustrasi CS dengan Lengkungan Cembung
            ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.only(bottom: 35, top: 10),
                child: Center(
                  child: SizedBox(
                    height: 170,
                    child: Image.asset(
                      'assets/images/cs.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.support_agent,
                          size: 100,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Isi / Topik Bantuan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Semua Topik",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _TopicCard(
                    icon: Icons.person_outline,
                    title: "Ajukan Pengaduan",
                    subtitle:
                        "Sampaikan kendala transaksi, penimbangan, atau layanan Bank Sampah di sini",
                    onTap: () => _launchURL(
                      "https://wa.me/6282141055878?text=Halo%20Admin,%20saya%20ingin%20mengajukan%20pengaduan",
                    ),
                  ),
                  const SizedBox(height: 12),

                  _TopicCard(
                    icon: Icons.search_rounded,
                    title: "Tentang Bank Sampah Sahabat Ibu",
                    subtitle:
                        "Dapatkan informasi dan pertanyaan yang sering diajukan oleh masyarakat",
                    onTap: () {
                      // isi link navigasi tentang bank sampah
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sosial Media / Hubungi Kami
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hubungi Kami",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        _ContactItem(
                          icon: FontAwesomeIcons.whatsapp,
                          iconBgColor: const Color(0xFFE8F8ED),
                          iconColor: const Color(0xFF25D366),
                          title: "WhatsApp",
                          subtitle: "+62 821-4105-5878",
                          onTap: () =>
                              _launchURL("https://wa.me/6282141055878"),
                        ),
                        _ContactItem(
                          icon: FontAwesomeIcons.instagram,
                          iconBgColor: const Color(0xFFFDF0F5),
                          iconColor: const Color(0xFFE1306C),
                          title: "Instagram",
                          subtitle: "@banksampah_sahabatibu",
                          onTap: () => _launchURL(
                            "https://instagram.com/banksampah_sahabatibu",
                          ),
                        ),
                        _ContactItem(
                          icon: FontAwesomeIcons.tiktok,
                          iconBgColor: const Color(0xFFF2F2F2),
                          iconColor: Colors.black,
                          title: "Tiktok",
                          subtitle: "@banksampah_sahabatibu",
                          onTap: () => _launchURL(
                            "https://tiktok.com/@banksampah_sahabatibu",
                          ),
                        ),
                        _ContactItem(
                          icon: FontAwesomeIcons.envelope,
                          iconBgColor: const Color(0xFFFFECEE),
                          iconColor: Colors.red,
                          title: "Email",
                          subtitle: "BSSIcontact@gmail.com",
                          onTap: () =>
                              _launchURL("mailto:BSSIcontact@gmail.com"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Widget Bantuan untuk List Topik
  Widget _TopicCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              child: Icon(icon, color: AppColors.green, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textDark,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // Widget Bantuan untuk Item Kontak
  Widget _ContactItem({
    required dynamic icon, // Dibuat dynamic agar fleksibel menerima FaIconData maupun IconData
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: iconBgColor,
        child: FaIcon(icon, color: iconColor, size: 16),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

// Custom Clipper untuk membuat lengkungan cembung bagian bawah header
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 25);

    final controlPoint = Offset(size.width / 2, size.height + 25);
    final endPoint = Offset(size.width, size.height - 25);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}