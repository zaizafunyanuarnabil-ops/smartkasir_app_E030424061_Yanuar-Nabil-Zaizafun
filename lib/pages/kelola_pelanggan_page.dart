import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pelanggan.dart';
import '../helpers/database_helper.dart';
import 'form_pelanggan_page.dart';

// Halaman Manajemen Master Pelanggan (CRM) dan Navigasi LBS
class KelolaPelangganPage extends StatefulWidget {
  const KelolaPelangganPage({super.key});

  @override
  State<KelolaPelangganPage> createState() => _KelolaPelangganPageState();
}

class _KelolaPelangganPageState extends State<KelolaPelangganPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Pelanggan> _pelangganList = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatDataPelanggan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Memuat seluruh data pelanggan dari SQLite
  Future<void> _muatDataPelanggan() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await DatabaseHelper.instance.getAllPelanggan();

      if (!mounted) return;

      setState(() {
        _pelangganList = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _tampilkanPesan('Gagal memuat data pelanggan: $e', Colors.red);
    }
  }

  // Pencarian pelanggan berdasarkan nama, nomor WA, atau kode
  Future<void> _cariPelanggan(String keyword) async {
    if (keyword.trim().isEmpty) {
      await _muatDataPelanggan();
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await DatabaseHelper.instance.searchPelanggan(
        keyword.trim(),
      );

      if (!mounted) return;

      setState(() {
        _pelangganList = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _tampilkanPesan('Pencarian gagal: $e', Colors.red);
    }
  }

  // Membuka rute Google Maps
  Future<void> _bukaRuteGoogleMaps(
    double latitude,
    double longitude,
    String namaPelanggan,
  ) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$latitude,$longitude'
      '&travelmode=driving',
    );

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final fallback = await launchUrl(url, mode: LaunchMode.platformDefault);

        if (!fallback && mounted) {
          _tampilkanPesan('Google Maps tidak dapat dibuka.', Colors.red);
        }
      }
    } catch (e) {
      if (!mounted) return;

      _tampilkanPesan('Gagal membuka rute $namaPelanggan: $e', Colors.red);
    }
  }

  // Menampilkan pesan SnackBar
  void _tampilkanPesan(String pesan, Color warna) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(pesan), backgroundColor: warna));
  }

  // Dialog konfirmasi hapus pelanggan
  void _konfirmasiHapusPelanggan(Pelanggan pelanggan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Hapus Pelanggan?')),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data pelanggan '
          '"${pelanggan.namaPelanggan}" '
          '(${pelanggan.kodePelanggan})?\n\n'
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                if (pelanggan.id == null) {
                  _tampilkanPesan('ID pelanggan tidak ditemukan.', Colors.red);
                  return;
                }

                await DatabaseHelper.instance.deletePelanggan(pelanggan.id!);

                if (!mounted) return;

                _tampilkanPesan(
                  'Pelanggan "${pelanggan.namaPelanggan}" '
                  'berhasil dihapus.',
                  Colors.orange,
                );

                await _cariPelanggan(_searchController.text);
              } catch (e) {
                if (!mounted) return;

                _tampilkanPesan('Gagal menghapus pelanggan: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  // Membuka form tambah pelanggan
  Future<void> _tambahPelanggan() async {
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const FormPelangganPage()),
    );

    if (refresh == true && mounted) {
      await _cariPelanggan(_searchController.text);
    }
  }

  // Membuka form edit pelanggan
  Future<void> _editPelanggan(Pelanggan pelanggan) async {
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => FormPelangganPage(pelanggan: pelanggan),
      ),
    );

    if (refresh == true && mounted) {
      await _cariPelanggan(_searchController.text);
    }
  }

  // Widget kartu pelanggan
  Widget _buildKartuPelanggan(Pelanggan p) {
    final hasGps = p.hasLocation;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header pelanggan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1E3A8A)
                      .withValues(alpha: 0.1),
                  child: Text(
                    p.namaPelanggan.isNotEmpty
                        ? p.namaPelanggan[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Nama dan tanggal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.namaPelanggan,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Terdaftar: ${p.createdAt}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge kode pelanggan
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0D9488)),
                    ),
                    child: Text(
                      p.kodePelanggan,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 18),

            // Nomor WhatsApp
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.nomorWa,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Alamat
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.alamat,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tombol aksi
            Row(
              children: [
                // Tombol rute Google Maps
                Expanded(
                  child: hasGps
                      ? ElevatedButton.icon(
                          onPressed: () {
                            _bukaRuteGoogleMaps(
                              p.latitude!,
                              p.longitude!,
                              p.namaPelanggan,
                            );
                          },
                          icon: const Icon(Icons.directions, size: 16),
                          label: const Text(
                            'Rute Google Maps',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 14,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'GPS Belum Terekam',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(width: 8),

                // Tombol edit
                IconButton.filledTonal(
                  onPressed: () => _editPelanggan(p),
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Edit Data Pelanggan',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: const Color(0xFF1E3A8A),
                  ),
                ),

                // Tombol hapus
                IconButton.filledTonal(
                  onPressed: () => _konfirmasiHapusPelanggan(p),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Hapus Pelanggan',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pelanggan & CRM'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // Bilah pencarian
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF8FAFC),
            child: TextField(
              controller: _searchController,
              onChanged: _cariPelanggan,
              decoration: InputDecoration(
                hintText: 'Cari nama, nomor WA, atau kode member...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _muatDataPelanggan();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),

          // Daftar pelanggan
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pelangganList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Pelanggan tidak ditemukan.'
                              : 'Belum ada data pelanggan.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Klik tombol di bawah untuk '
                          'menambah member baru.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pelangganList.length,
                    itemBuilder: (context, index) {
                      final p = _pelangganList[index];
                      return _buildKartuPelanggan(p);
                    },
                  ),
          ),
        ],
      ),

      // Tombol tambah pelanggan
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahPelanggan,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Member'),
      ),
    );
  }
}
