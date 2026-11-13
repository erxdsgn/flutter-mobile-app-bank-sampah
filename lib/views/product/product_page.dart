// lib/views/product/product_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../widgets/primary_app_bar.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_input.dart';
import '../../widgets/skeleton_box.dart';
import 'product_detail_page.dart';

class ProductPage extends StatefulWidget {
  final String tokenWarga;

  const ProductPage({super.key, required this.tokenWarga});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // Nomor WhatsApp admin (format internasional). Dipakai jika produk
  // tidak punya nomor_wa sendiri di database.
  static const String _adminPhone = "6281234567890";

  final ProductService _productService = ProductService();
  late Future<List<ProductModel>> _futureProducts;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _futureProducts = _load();
  }

  Future<List<ProductModel>> _load() =>
      _productService.getKatalogProduk(widget.tokenWarga);

  /// Tarik ke bawah untuk mengambil data terbaru (stok & deskripsi).
  Future<void> _refresh() async {
    final future = _load();
    setState(() => _futureProducts = future);
    await future.catchError((_) => <ProductModel>[]);
  }

  Future<void> _launchWhatsApp(ProductModel product) async {
    final phone = (product.nomorWa != null && product.nomorWa!.isNotEmpty)
        ? product.nomorWa!
        : _adminPhone;
    final message =
        "Halo admin, saya tertarik dengan produk *${product.namaProduk}*. Apakah stoknya masih tersedia?";
    final uri =
        Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak dapat membuka WhatsApp")),
      );
    }
  }

  void _showDetail(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ProductDetailPage(
          product: product,
          onPesan: () => _launchWhatsApp(product),
        ),
      ),
    );
  }

  Widget _pesan(String teks, {Color color = AppColors.muted}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            teks,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 14),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const PrimaryAppBar(
        title: "Produk Daur Ulang",
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ═══ 1. SEARCH BAR ═══
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchInput(
              hintText: "Cari produk daur ulang...",
              onChanged: (value) =>
                  setState(() => _keyword = value.toLowerCase().trim()),
            ),
          ),

          // ═══ 2. GRID PRODUK ═══
          Expanded(
            child: FutureBuilder<List<ProductModel>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _ProductGridSkeleton();
                }
                if (snapshot.hasError) {
                  return _pesan("Gagal memuat produk:\n${snapshot.error}",
                      color: Colors.red);
                }

                final semua = snapshot.data ?? [];
                if (semua.isEmpty) {
                  return _pesan("Belum ada produk daur ulang tersedia.");
                }

                final productList = semua
                    .where((p) => p.namaProduk.toLowerCase().contains(_keyword))
                    .toList();
                if (productList.isEmpty) {
                  return _pesan("Produk tidak ditemukan.");
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refresh,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      final product = productList[index];

                      return ProductCard(
                        name: product.namaProduk,
                        price: product.hargaFormatted,
                        imagePath: product.fotoUrl,
                        onTap: () => _showDetail(product),
                        onTapWhatsApp: () => _launchWhatsApp(product),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// SKELETON LOADING GRID KATALOG PRODUK
// ======================================================

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Skeleton
              Expanded(
                child: SkeletonBox(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 12,
                ),
              ),
              SizedBox(height: 10),
              // Nama Produk Skeleton
              SkeletonBox(width: 100, height: 12),
              SizedBox(height: 6),
              // Subtitle / Stok Skeleton
              SkeletonBox(width: 60, height: 10),
              SizedBox(height: 12),
              // Harga & Button WA Skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 65, height: 14),
                  SkeletonBox(width: 32, height: 32, borderRadius: 16),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}