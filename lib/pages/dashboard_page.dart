import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/produk.dart';
import '../helpers/database_helper.dart';
import 'form_produk_page.dart';
import 'kelola_pelanggan_page.dart';

// Halaman Beranda & Katalog Kasir SmartKasir
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Kategori aktif
  int _kategoriTerpilih = 0;

  final List<String> _kategoriList = ['Semua', 'Makanan', 'Minuman', 'Snack'];

  // Future data produk SQLite
  late Future<List<Produk>> _produkFuture;

  // Controller pencarian
  final TextEditingController _searchController = TextEditingController();

  String _keywordPencarian = '';

  // Format Rupiah
  String _formatRupiah(double nominal) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return formatCurrency.format(nominal);
  }

  @override
  void initState() {
    super.initState();

    // Memuat data produk pertama kali
    _produkFuture = _ambilFutureProduk();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Mengambil Future produk sesuai pencarian atau kategori
  Future<List<Produk>> _ambilFutureProduk() {
    if (_keywordPencarian.trim().isNotEmpty) {
      return DatabaseHelper.instance.searchProduk(_keywordPencarian.trim());
    }

    return DatabaseHelper.instance.getProdukByKategori(
      _kategoriList[_kategoriTerpilih],
    );
  }

  // Memuat ulang data katalog
  void _muatDataProduk() {
    if (!mounted) return;

    setState(() {
      _produkFuture = _ambilFutureProduk();
    });
  }

  // Dialog konfirmasi hapus produk
  void _konfirmasiHapusProduk(Produk item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Hapus Produk?')),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus '
          '"${item.nama}" dari database SQLite?\n\n'
          'Data yang dihapus tidak dapat dipulihkan kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                if (item.id == null) {
                  _tampilkanPesan('ID produk tidak ditemukan.', Colors.red);
                  return;
                }

                await DatabaseHelper.instance.deleteProduk(item.id!);

                if (!mounted) return;

                _tampilkanPesan(
                  'Produk "${item.nama}" berhasil dihapus!',
                  Colors.red.shade700,
                );

                _muatDataProduk();
              } catch (e) {
                if (!mounted) return;

                _tampilkanPesan('Gagal menghapus produk: $e', Colors.red);
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Menampilkan SnackBar
  void _tampilkanPesan(String pesan, Color warna) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Badge indikator stok
  Widget _buildBadgeStok(int stok) {
    Color warnaLatar;
    Color warnaTeks;
    String label;

    if (stok <= 0) {
      warnaLatar = Colors.red.shade100;
      warnaTeks = Colors.red.shade900;
      label = 'Habis';
    } else if (stok <= 5) {
      warnaLatar = Colors.amber.shade100;
      warnaTeks = Colors.amber.shade900;
      label = 'Sisa $stok';
    } else {
      warnaLatar = Colors.green.shade100;
      warnaTeks = Colors.green.shade900;
      label = 'Stok $stok';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: warnaTeks,
        ),
      ),
    );
  }

  // Navigasi edit produk
  Future<void> _editProduk(Produk item) async {
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormProdukPage(produk: item)),
    );

    if (refresh == true && mounted) {
      _muatDataProduk();
    }
  }

  // Navigasi tambah produk
  Future<void> _tambahProduk() async {
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormProdukPage()),
    );

    if (refresh == true && mounted) {
      _muatDataProduk();
    }
  }

  // Navigasi kelola pelanggan
  Future<void> _bukaKelolaPelanggan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KelolaPelangganPage()),
    );

    if (mounted) {
      _muatDataProduk();
    }
  }

  // Kartu produk
  Widget _buildProductCard(Produk item) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto produk
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Stack(
              children: [
                Image.network(
                  item.gambarUrl,
                  height: 105,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 105,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.fastfood,
                        size: 36,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),

                // Badge promo
                if (item.diskonPersen > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PROMO ${item.diskonPersen}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Deskripsi produk
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                _buildBadgeStok(item.stok),

                const SizedBox(height: 4),

                Text(
                  _formatRupiah(item.hargaJual),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Tombol aksi produk
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Edit
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF1E3A8A),
                  ),
                  tooltip: 'Edit Produk',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => _editProduk(item),
                ),

                // Hapus
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                  tooltip: 'Hapus Produk',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => _konfirmasiHapusProduk(item),
                ),

                // Tambah ke kasir
                IconButton(
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    size: 18,
                    color: Color(0xFF1E3A8A),
                  ),
                  tooltip: 'Tambah ke Kasir',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _tampilkanPesan(
                      '${item.nama} dipilih untuk transaksi kasir',
                      const Color(0xFF1E3A8A),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Banner penjualan harian
  Widget _buildBannerPenjualan() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Penjualan Hari Ini',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Rp 845.000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  '34 Transaksi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick action button
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Kelola pelanggan
          Expanded(
            child: InkWell(
              onTap: _bukaKelolaPelanggan,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 18,
                      color: Color(0xFF1E3A8A),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Kelola Pelanggan',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Tambah produk
          Expanded(
            child: InkWell(
              onTap: _tambahProduk,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_box_outlined, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Tambah Produk',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kotak pencarian
  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          _keywordPencarian = val;
          _muatDataProduk();
        },
        decoration: InputDecoration(
          hintText: 'Cari nama produk ...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
          suffixIcon: _keywordPencarian.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _keywordPencarian = '';
                    _muatDataProduk();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  // Filter kategori
  Widget _buildFilterKategori() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kategoriList.length,
        itemBuilder: (context, index) {
          final isSelected = _kategoriTerpilih == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_kategoriList[index]),
              selected: isSelected,
              selectedColor: const Color(0xFF1E3A8A),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (!selected) return;

                setState(() {
                  _kategoriTerpilih = index;
                  _searchController.clear();
                  _keywordPencarian = '';
                  _produkFuture = _ambilFutureProduk();
                });
              },
            ),
          );
        },
      ),
    );
  }

  // Tampilan saat produk kosong
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            _keywordPencarian.isNotEmpty
                ? 'Produk "$_keywordPencarian" tidak ditemukan.'
                : 'Belum ada produk pada kategori ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Katalog FutureBuilder
  Widget _buildKatalogProduk() {
    return Expanded(
      child: FutureBuilder<List<Produk>>(
        future: _produkFuture,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Terjadi kesalahan memuat database:\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Data kosong
          final daftarProduk = snapshot.data ?? [];

          if (daftarProduk.isEmpty) {
            return _buildEmptyState();
          }

          // Data tersedia
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 230,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: daftarProduk.length,
            itemBuilder: (context, index) {
              return _buildProductCard(daftarProduk[index]);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // AppBar
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.point_of_sale, color: Color(0xFFFBBF24)),
            SizedBox(width: 8),
            Text(
              'SmartKasir',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Tambah Produk Baru',
            onPressed: _tambahProduk,
          ),
        ],
      ),

      // Body
      body: Column(
        children: [
          // 1. Banner penjualan
          _buildBannerPenjualan(),

          // 2. Quick actions
          _buildQuickActions(),

          const SizedBox(height: 12),

          // 3. Search
          _buildSearchBox(),

          const SizedBox(height: 12),

          // 4. Filter kategori
          _buildFilterKategori(),

          const SizedBox(height: 12),

          // 5. Katalog produk
          _buildKatalogProduk(),
        ],
      ),

      // Floating button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahProduk,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }
}
