// lib/views/product/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../widgets/skeleton_box.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  /// Dipanggil saat tombol "Pesan" ditekan (dibuka WhatsApp oleh ProductPage).
  final VoidCallback? onPesan;

  const ProductDetailPage({super.key, required this.product, this.onPesan});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.fotoUrl;
    final stokMenipis = product.stok <= 5;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // --- Header (Tombol Close) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCCCCCC)),
                    ),
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),

          // --- Isi Detail Produk (seluruh isi bisa di-scroll) ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar produk: persegi (1:1) dengan Skeleton Loading
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            color: const Color(0xFFE8F5E9),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const SkeletonBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        borderRadius: 24,
                                      );
                                    },
                                    errorBuilder: (_, __, ___) =>
                                        const _FotoKosong(),
                                  )
                                : const _FotoKosong(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Judul & Ikon Hati ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.namaProduk,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const FaIcon(FontAwesomeIcons.solidHeart,
                          color: AppColors.muted),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- Harga & Stok ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF45DD60), Color(0xFF38B54E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.sell_outlined,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            product.hargaFormatted,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stokMenipis
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 14,
                                color: stokMenipis
                                    ? Colors.orange.shade800
                                    : AppColors.muted),
                            const SizedBox(width: 4),
                            Text(
                              'Stok : ${product.stok}',
                              style: TextStyle(
                                fontSize: 12,
                                color: stokMenipis
                                    ? Colors.orange.shade800
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Banner Info ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.green, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Hubungi admin untuk menukar / menanyakan ketersediaan barang.",
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Deskripsi (dari database) ---
                  const Text(
                    "Deskripsi",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.punyaDeskripsi
                        ? product.deskripsi!.trim()
                        : "Belum ada deskripsi untuk produk ini.",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // --- Tombol Pesan (WhatsApp) ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onPesan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const FaIcon(FontAwesomeIcons.whatsapp,
                    color: Colors.white, size: 20),
                label: const Text(
                  "Pesan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FotoKosong extends StatelessWidget {
  const _FotoKosong();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image, size: 80, color: AppColors.muted),
    );
  }
}