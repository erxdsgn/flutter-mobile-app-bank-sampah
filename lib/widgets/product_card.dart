// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String imagePath; 
  final VoidCallback? onTap;           // 1. Tambahkan parameter onTap untuk card
  final VoidCallback? onTapWhatsApp;   // Aksi jika tombol WA diklik

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.imagePath,
    this.onTap,                        // 2. Daftarkan di constructor
    this.onTapWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    // 3. Bungkus Container utama dengan InkWell agar seluruh card bisa diklik
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.avatarBorder,
                    child: imagePath.isNotEmpty
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: FaIcon(
                                  FontAwesomeIcons.image,
                                  color: AppColors.muted,
                                  size: 30,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: FaIcon(
                              FontAwesomeIcons.image,
                              color: AppColors.muted,
                              size: 30,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            
            // Bagian Teks & Tombol WhatsApp
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      // Tombol Hubungi Admin / WhatsApp
                      InkWell(
                        onTap: onTapWhatsApp,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}