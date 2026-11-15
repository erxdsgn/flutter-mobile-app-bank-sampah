import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';
import '../../models/about_model.dart';
import '../profile/about-detail_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static List<FaqCategory> faqData = [ 
    FaqCategory(
      title: "Bank Sampah",
      items: [
        FaqItem(
          question: "Apa itu Bank Sampah Sahadat Ibu?",
          answer: "Bank Sampah Sahadat Ibu adalah platform digital yang membantu Anda mengelola sampah rumah tangga menjadi rupiah. Kami mengedukasi masyarakat untuk memilah sampah dan menabungnya, sehingga lingkungan menjadi bersih sekaligus menambah penghasilan.",
          relatedArticle: "Mengenal Bank Sampah Sahadat Ibu",
        ),
        FaqItem(
          question: "Bagimana cara setor sampah?",
          answer: "1. Pilah sampah Anda (plastik, kertas, kaleng) dari sampah organik.\n2. Pastikan sampah dalam keadaan bersih dan kering.\n3. Bawa sampah ke lokasi Bank Sampah Sahabat Ibu.\n4. Admin Bank Sampah akan menimbang dan menginput data setoran Anda ke sistem.\n5. Saldo akan otomatis masuk ke akun aplikasi Anda.\n6. Noted: Perhatikan Jadwal Setoran setiap kelompok ( Kelompok A atau B)",
        ),
        FaqItem(
          question: "Bagaimana cara menjadi nasabah?",
          answer:  "Cukup daftar melalui aplikasi ini dengan mengisi data diri yang valid. Setelah melakukan registrasi dan akun terverifikasi oleh admin, Anda sudah resmi menjadi nasabah dan bisa mulai menyetor sampah.",
        ),
        FaqItem(
          question: "Bagaimana proses pencairan saldo?",
          answer: "Pencairan saldo dapat dilakukan setiap satu tahun sekali pada saat bulan Ramadhan. Saldo minimal yang dapat dicairkan adalah Rp 10.000. Proses transfer akan diproses oleh admin maksimal 2x24 jam kerja ke rekening bank atau e-wallet yang terdaftar.",
        ),
        FaqItem(
          question: "Layanan apa saja yang disediakan Bank Sampah Sahabat Ibu?",
          answer: "Kami menyediakan layanan:\n1. Penimbangan dan setoran sampah.\n2. Pengolahan produk daur ulang dan siap jual seperti tas dari tutup botol, kotak tisu, dll. semua produk bisa dilihat di halaman produk daur ulang.\n3. Edukasi pengelolaan sampah (kompos, kerajinan, dll).\n4. Menghadirkan Event menarik bank sampah paling lama 3 bulan sekali.\n5. Tabungan Bank Sampah.",
        ),
      ],
    ),
    FaqCategory(
      title: "Akun Nasabah",
      items: [
        FaqItem(
          question: "Bagaimana cara mendaftar akun?",
          answer: "Unduh aplikasi, pilih menu 'Daftar', lalu isi data diri seperti Nama, NIK, WhatsApp, Email, Anggota Keluarga, Password, Alamat serta Anggota Kelompok. Setelah registrasi berhasil, Anda bisa langsung login dan melengkapi profil Anda.",
        ),
        FaqItem(
          question: "Apa saja syarat menjadi nasabah?",
          answer: "Syarat menjadi nasabah:\n1. Warga Negara Indonesia (memiliki KTP/NIK).\n2. Berdomisili di area jangkauan layanan Bank Sampah Sahadat Ibu.\n3. Memiliki nomor WhatsApp dan email aktif.\n4. Menyetujui syarat dan ketentuan yang berlaku.",
        ),
        FaqItem(
          question: "Data apa saja yang harus diinputkan?",
          answer: "Saat mendaftar, Anda wajib mengisi:\n- Nama Lengkap (sesuai KTP)\n- NIK (Nomor Induk Kependudukan)\n- Nomor WhatsApp aktif\n- Alamat lengkap (domisili)\n- Email aktif\n- Password yang aman\n- Jumlah anggota keluarga.\n- Selanjutnya data yang perlu dilengkapi setelah nasabah berhasil login adalah, E-Wallet/Rekening aktif, Jenis kelompok (A atau B)",
        ),
        FaqItem(
          question: "Apa yang boleh dan tidak boleh dilakukan nasabah?",
          answer: "Yang BOLEH: Memilah sampah dengan benar, menyetor sampah sesuai jadwal, dan menjaga kebersihan lingkungan.\n\nYang TIDAK BOLEH: Menyetor sampah medis/B3 (baterai, masker, popok), menyetor sampah basah/organik, memalsukan data profil, atau memindahtangankan akun ke orang lain tanpa izin admin.",
        ),
        FaqItem(
          question: "Bagaimana jika ada nasabah yang tidak aktif setor sampah?",
          answer: "Bagi nasabah yang tidak aktif atau jarang menyetorkan sampah dalam 3 - 6 Bulan, maka akan dianggap tidak aktif dan akun otomatis terhapus. Dan jika ingin mengaktifkan kembali, nasabah disarankan untuk mendaftar ulang sebagai nasabah baru.",
        ),
        FaqItem(
          question: "Bagaimana jika nasabah lupa password?",
          answer: "Klik tombol 'Lupa Password' di halaman Login. Masukkan email yang terdaftar. Anda akan menerima kode OTP atau tautan untuk mengatur ulang password baru.\n Jika hanya ingin mengganti password (masih ingat) nasabah bisa langsung mengunjungi menu profile lalu menu Password setelah itu nasabah bisa melakukan perubahan password ",
        ),
      ],
    ),
    FaqCategory(
      title: "Keamanan Akun",
      items: [
        FaqItem(
          question: "Apakah data saya aman?",
          answer: "Ya, sangat aman. Data pribadi Anda (NIK, alamat, nomor HP, dll) dienkripsi dan disimpan di server yang aman. Kami berkomitmen untuk tidak menyalahgunakan data Anda sesuai dengan Undang-Undang Perlindungan Data Pribadi (UU PDP).",
        ),
        FaqItem(
          question: "Bagaimana jika akun saya diretas?",
          answer: "Segera hubungi admin melalui menu 'Bantuan' di aplikasi. Kami akan membekukan akun sementara untuk mencegah kerugian lebih lanjut, lalu memandu Anda untuk memulihkan akun dengan verifikasi data diri.",
        ),
        FaqItem(
          question: "Apakah data saldo saya bisa dimanipulasi?",
          answer: "Tidak. Semua transaksi setoran dan pencairan saldo dicatat secara sistem oleh petugas dan admin. Riwayat transaksi di aplikasi Anda bersifat real-time dan sesuai dengan catatan server kami.",
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            // header
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
                    "Tentang Kami",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
            ),

            // search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFEEF6F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Cari pertanyaanmu",
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppColors.muted),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // breadcrumb
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text("FAQ", style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  Icon(Icons.chevron_right, size: 14, color: AppColors.muted),
                  Text("Tentang Kami", style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // list faq
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: faqData.length,
                itemBuilder: (context, index) {
                  final category = faqData[index];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.format_list_bulleted, color: Colors.white, size: 18),
                        ),
                        title: Text(
                          category.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        children: category.items.map((faqItem) {
                          return Column(
                            children: [
                              const Divider(height: 1, color: Color(0xFFEEEEEE)),
                              ListTile(
                                title: Text(
                                  faqItem.question,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FaqDetailPage(faqItem: faqItem),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}