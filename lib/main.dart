import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- TAMBAHKAN IMPORT INI
import 'package:intl/date_symbol_data_local.dart';
import 'views/auth/login_page.dart';

void main() async {
  // 1. Pastikan Flutter engine sudah siap sebelum menjalankan fungsi async
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Firebase
  await Firebase.initializeApp(); // <-- TAMBAHKAN BARIS INI

  // 3. Aktifkan format tanggal Bahasa Indonesia ('id_ID')
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bank Sampah',
      home: const LoginPage(),
    );
  }
}