import 'package:flutter/material.dart';

// Mengimpor halaman Beranda dan Katalog Produk (Modul M11)
import 'dashboard_page.dart';

// Mengimpor halaman Profil Toko dan Kelola Karyawan (Modul M12)
import 'profil_toko_page.dart';

// Kerangka Navigasi Utama Aplikasi SmartKasir
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  // 1. INDEKS TAB MENU AKTIF
  // Default: 0 = Beranda
  int _currentIndex = 0;

  // 2. DAFTAR HALAMAN UTAMA SMARTKASIR
  final List<Widget> _pages = [
    // Tab 0: Beranda dan Katalog Produk (Modul M11)
    const DashboardPage(),

    // Tab 1: Transaksi Kasir POS (Modul M14)
    const Center(
      child: Text(
        'Menu 2: Transaksi Kasir POS (Modul M14)',
        style: TextStyle(fontSize: 16),
      ),
    ),

    // Tab 2: Riwayat Penjualan dan Laporan (Modul M14)
    const Center(
      child: Text(
        'Menu 3: Riwayat Penjualan & Laporan (Modul M14)',
        style: TextStyle(fontSize: 16),
      ),
    ),

    // Tab 3: Profil Toko dan Kelola Karyawan (Modul M12)
    const ProfilTokoPage(),
  ];

  // ==========================================
  // 3. TAMPILAN NAVIGASI UTAMA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // MENAMPILKAN HALAMAN SESUAI TAB AKTIF
      // IndexedStack mempertahankan state setiap halaman
      body: IndexedStack(index: _currentIndex, children: _pages),

      // ========================================
      // 4. BOTTOM NAVIGATION BAR
      // ========================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),

        child: BottomNavigationBar(
          // Indeks menu yang sedang aktif
          currentIndex: _currentIndex,

          // Fungsi perpindahan halaman
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },

          // Mempertahankan seluruh item navigasi tetap terlihat
          type: BottomNavigationBarType.fixed,

          backgroundColor: Colors.white,

          // Warna tab aktif
          selectedItemColor: const Color(0xFF1E3A8A),

          // Warna tab tidak aktif
          unselectedItemColor: Colors.grey.shade500,

          // Gaya label tab aktif
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),

          // Gaya label tab tidak aktif
          unselectedLabelStyle: const TextStyle(fontSize: 10),

          // Daftar empat menu utama
          items: const [
            // TAB 0: BERANDA
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Beranda',
            ),

            // TAB 1: KASIR
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Kasir',
            ),

            // TAB 2: RIWAYAT
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Riwayat',
            ),

            // TAB 3: TOKO
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
