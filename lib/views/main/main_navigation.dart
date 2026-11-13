// lib/views/main/main_navigation.dart
import 'package:flutter/material.dart';

import '../../widgets/bottom_nav_bar.dart';
// import '../../widgets/placeholder_page.dart'; // Hapus atau biarkan jika tidak dipakai
import '../history/history_page.dart';
import '../home/home_page.dart';
import '../product/product_page.dart';
import '../profile/profile_page.dart'; // 👈 1. Import ProfilePage Anda di sini (sesuaikan path foldernya jika berbeda)

class MainNavigation extends StatefulWidget {
  final String userName;
  final String tokenWarga;

  const MainNavigation({
    super.key,
    this.userName = 'NASABAH',
    required this.tokenWarga,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const int _tabBeranda = 0;
  static const int _tabProduk = 1;
  static const int _tabRiwayat = 2;
  static const int _tabProfile = 3;

  int _currentIndex = _tabBeranda;

  final GlobalKey<HistoryPageState> _historyKey = GlobalKey<HistoryPageState>();

  late final List<Widget> _pages;

  static const _items = [
    NavItemData(icon: Icons.home_outlined, label: 'Beranda'),
    NavItemData(icon: Icons.shopping_cart_outlined, label: 'Produk'),
    NavItemData(icon: Icons.description_outlined, label: 'Riwayat'),
    NavItemData(icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        userName: widget.userName,
        onOpenProduk: () => _goToTab(_tabProduk),
        onOpenRiwayat: () => _goToTab(_tabRiwayat),
        onOpenProfile: () => _goToTab(_tabProfile), // 👈 2. Menghubungkan tombol profil di beranda ke tab profile
      ),
      ProductPage(tokenWarga: widget.tokenWarga),
      HistoryPage(key: _historyKey, token: widget.tokenWarga),
      const ProfilePage(), // 👈 3. Mengganti PlaceholderPage dengan ProfilePage asli
    ];
  }

  void _goToTab(int index) {
    final pindahKeRiwayat = index == _tabRiwayat && _currentIndex != _tabRiwayat;
    setState(() => _currentIndex = index);
    if (pindahKeRiwayat) {
      _historyKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavBar(
        items: _items,
        currentIndex: _currentIndex,
        onTap: _goToTab,
      ),
    );
  }
}