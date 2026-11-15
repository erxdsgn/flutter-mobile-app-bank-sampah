import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';
import '../../models/about_model.dart';

class FaqDetailPage extends StatelessWidget {
  final FaqItem faqItem;

  const FaqDetailPage({super.key, required this.faqItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    "FAQ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
            ),

            //breadcrumb
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text("FAQ", style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const Icon(Icons.chevron_right, size: 14, color: AppColors.muted),
                  const Text("Tentang Gemi", style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const Icon(Icons.chevron_right, size: 14, color: AppColors.muted),
                  Expanded(
                    child: Text(
                      faqItem.question,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            //konten
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faqItem.question,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 16),
                    
                    Text(
                      faqItem.answer,
                      style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.6),
                    ),

                    const SizedBox(height: 32),
                    const Divider(color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 16),

                    // artikel opsional
                    if (faqItem.relatedArticle != null) ...[
                      const Text(
                        "Artikel Terkait",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {},
                        child: Text(
                          faqItem.relatedArticle!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF38B54E),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}