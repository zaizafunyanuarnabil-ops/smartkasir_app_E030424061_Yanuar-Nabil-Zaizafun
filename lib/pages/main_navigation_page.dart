import 'package:flutter/material.dart';

// Mengimpor halaman DashboardPage untuk tab menu pertama (Beranda)
import 'dashboard_page.dart';

// Widget MainNavigationPage untuk mengelola navigasi bawah aplikasi
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

// Kelas pengelola state dan logika navigasi bawah SmartKasir
class _MainNavigationPageState extends State<MainNavigationPage> {
  // --- DEKLARASI VARIABEL STATE NAVIGASI ---

  // Indeks tab yang sedang aktif (0 = Beranda)
  int _currentIndex = 0;

  // Koleksi halaman menu operasional kasir
  final List<Widget> _pages = [
    const DashboardPage(),

    // Indeks 1: POS Kasir
    const Center(
      child: Text(
        'Menu 2: Transaksi Kasir POS (Modul M14)',
        style: TextStyle(fontSize: 16),
      ),
    ),

    // Indeks 2: Riwayat Penjualan dan Laporan
    const Center(
      child: Text(
        'Menu 3: Riwayat Penjualan & Laporan (Modul M12)',
        style: TextStyle(fontSize: 16),
      ),
    ),

    // Indeks 3: Profil Toko dan Pengaturan
    const Center(
      child: Text(
        'Menu 4: Profil Toko & Pengaturan (Modul M12)',
        style: TextStyle(fontSize: 16),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- KONTROL PERGANTIAN HALAMAN BERDASARKAN INDEKS ---
      body: _pages[_currentIndex],

      // --- NAVIGASI BAWAH APLIKASI ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            // Efek bayangan halus pada navigasi bawah
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),

        // Komponen navigasi bawah dengan 4 tab
        child: BottomNavigationBar(
          currentIndex: _currentIndex,

          // Event ketika pengguna memilih tab
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },

          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,

          // Warna tab aktif dan tidak aktif
          selectedItemColor: const Color(0xFF1E3A8A),
          unselectedItemColor: Colors.grey.shade500,

          // Pengaturan teks label
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 10),

          // --- DAFTAR 4 ITEM NAVIGASI BAWAH ---
          items: const [
            // Tab 1: Beranda
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Beranda',
            ),

            // Tab 2: Kasir POS
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Kasir',
            ),

            // Tab 3: Riwayat Transaksi dan Laporan
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Riwayat',
            ),

            // Tab 4: Profil Toko dan Pengaturan
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Toko',
            ),
          ],
        ),
      ),
    );
  }
}
