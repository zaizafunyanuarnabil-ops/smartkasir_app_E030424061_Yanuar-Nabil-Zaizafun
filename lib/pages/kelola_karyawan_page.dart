import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/karyawan.dart';
import '../helpers/database_helper.dart';
import 'form_karyawan_page.dart';

// Halaman Manajemen Daftar Staf Kasir
// dan Penetapan Kasir Aktif

class KelolaKaryawanPage extends StatefulWidget {
  const KelolaKaryawanPage({super.key});

  @override
  State<KelolaKaryawanPage> createState() => _KelolaKaryawanPageState();
}

class _KelolaKaryawanPageState extends State<KelolaKaryawanPage> {
  // 1. FUTURE DAFTAR KARYAWAN DARI SQLITE
  late Future<List<Karyawan>> _karyawanFuture;

  // 2. DATA KASIR AKTIF
  int? _activeCashierId;
  String _activeCashierName = 'Belum Ditentukan';

  @override
  void initState() {
    super.initState();

    // Memuat data awal sebelum halaman ditampilkan
    _karyawanFuture = DatabaseHelper.instance.getAllKaryawan();

    _muatKasirAktif();
  }

  // ==========================================
  // MEMUAT DATA KASIR AKTIF
  // ==========================================

  Future<void> _muatKasirAktif() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _activeCashierId = prefs.getInt('active_cashier_id');

      _activeCashierName =
          prefs.getString('active_cashier_name') ?? 'Belum Ditentukan';
    });
  }

  // ==========================================
  // MEMUAT ULANG DAFTAR KARYAWAN
  // ==========================================

  void _muatData() {
    setState(() {
      _karyawanFuture = DatabaseHelper.instance.getAllKaryawan();
    });
  }

  // ==========================================
  // MENETAPKAN KASIR AKTIF
  // ==========================================

  Future<void> _setKasirAktif(Karyawan staf) async {
    // Memastikan ID karyawan tersedia
    if (staf.id == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('active_cashier_id', staf.id!);

    await prefs.setString('active_cashier_name', staf.namaKaryawan);

    if (!mounted) return;

    setState(() {
      _activeCashierId = staf.id;
      _activeCashierName = staf.namaKaryawan;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kasir aktif giliran saat ini: "${staf.namaKaryawan}"'),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // KONFIRMASI DAN HAPUS KARYAWAN
  // ==========================================

  Future<void> _konfirmasiHapusKaryawan(Karyawan staf) async {
    // PROTEKSI: KASIR AKTIF TIDAK BOLEH DIHAPUS

    if (staf.id == _activeCashierId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Karyawan "${staf.namaKaryawan}" sedang aktif bertugas! '
            'Ganti kasir aktif terlebih dahulu sebelum menghapus.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // DIALOG KONFIRMASI HAPUS
    final konfirmasi = await showDialog<bool>(
      context: context,

      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),

            SizedBox(width: 8),

            Text('Hapus Karyawan?'),
          ],
        ),

        content: Text(
          'Apakah Anda yakin ingin menghapus staf '
          '"${staf.namaKaryawan}" (${staf.peran})? '
          'Data tidak dapat dipulihkan.',
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false);
            },

            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),

            onPressed: () {
              Navigator.pop(ctx, true);
            },

            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    // JIKA PENGGUNA MEMILIH BATAL
    if (konfirmasi != true || !mounted) return;

    // EKSEKUSI PENGHAPUSAN DATA SQLITE
    try {
      if (staf.id == null) return;

      await DatabaseHelper.instance.deleteKaryawan(staf.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data staf "${staf.namaKaryawan}" telah dihapus!'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // MEMUAT ULANG DAFTAR KARYAWAN
      _muatData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus karyawan: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================
  // BADGE PERAN / JABATAN KARYAWAN
  // ==========================================

  Widget _buildRoleBadge(String peran) {
    Color bg;
    Color fg;

    if (peran == 'Manajer') {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
    } else if (peran == 'Admin') {
      bg = Colors.blue.shade100;
      fg = Colors.blue.shade900;
    } else {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),

      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),

      child: Text(
        peran,

        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  // ==========================================
  // MEMBUKA FORM TAMBAH KARYAWAN
  // ==========================================

  Future<void> _tambahKaryawan() async {
    final refresh = await Navigator.push<bool>(
      context,

      MaterialPageRoute(builder: (context) => const FormKaryawanPage()),
    );

    if (!mounted) return;

    if (refresh == true) {
      _muatData();
    }
  }

  // ==========================================
  // MEMBUKA FORM EDIT KARYAWAN
  // ==========================================

  Future<void> _editKaryawan(Karyawan staf) async {
    final refresh = await Navigator.push<bool>(
      context,

      MaterialPageRoute(builder: (context) => FormKaryawanPage(karyawan: staf)),
    );

    if (!mounted) return;

    if (refresh == true) {
      _muatData();
    }
  }

  // ==========================================
  // TAMPILAN HALAMAN KELOLA KARYAWAN
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // APP BAR
      appBar: AppBar(
        title: const Text(
          'Kelola Karyawan & Kasir',

          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),

        backgroundColor: const Color(0xFF1E3A8A),

        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          // ==================================
          // 1. BANNER KASIR AKTIF
          // ==================================

          Container(
            margin: const EdgeInsets.all(16),

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],

                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

              borderRadius: BorderRadius.circular(14),

              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),

            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white24,

                  child: Icon(
                    Icons.verified_user,
                    color: Colors.amber,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'KASIR AKTIF BERJAGA SAAT INI',

                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        _activeCashierName,

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==================================
          // 2. DAFTAR KARYAWAN SQLITE
          // ==================================
          Expanded(
            child: FutureBuilder<List<Karyawan>>(
              future: _karyawanFuture,

              builder: (context, snapshot) {
                // LOADING
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // ERROR
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),

                      child: Text(
                        'Terjadi kesalahan database: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // DATA KARYAWAN
                final daftarStaf = snapshot.data ?? [];

                // KONDISI KOSONG
                if (daftarStaf.isEmpty) {
                  return const Center(
                    child: Text('Belum ada data karyawan terdaftar.'),
                  );
                }

                // MENAMPILKAN DAFTAR KARYAWAN
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),

                  itemCount: daftarStaf.length,

                  itemBuilder: (context, index) {
                    final staf = daftarStaf[index];

                    final isActive = staf.id == _activeCashierId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE2E8F0),

                          width: isActive ? 2 : 1,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),

                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),

                        // FOTO INISIAL KARYAWAN
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey.shade200,

                          foregroundColor: isActive
                              ? Colors.white
                              : Colors.grey.shade700,

                          child: Text(
                            staf.namaKaryawan.isNotEmpty
                                ? staf.namaKaryawan[0].toUpperCase()
                                : '?',

                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        // NAMA DAN PERAN KARYAWAN
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                staf.namaKaryawan,

                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            _buildRoleBadge(staf.peran),
                          ],
                        ),

                        // INFORMASI PIN DAN ID
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),

                          child: Text(
                            'PIN: •••• | ID: #${staf.id}',

                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        // TOMBOL AKSI
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            // TOMBOL KASIR AKTIF
                            IconButton(
                              icon: Icon(
                                isActive ? Icons.star : Icons.star_border,

                                color: isActive
                                    ? Colors.amber.shade700
                                    : Colors.grey,
                              ),

                              tooltip: isActive
                                  ? 'Kasir Aktif'
                                  : 'Set sebagai Kasir Aktif',

                              onPressed: isActive
                                  ? null
                                  : () => _setKasirAktif(staf),
                            ),

                            // TOMBOL EDIT
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Color(0xFF1E3A8A),
                              ),

                              tooltip: 'Edit Data',

                              onPressed: () {
                                _editKaryawan(staf);
                              },
                            ),

                            // TOMBOL HAPUS
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),

                              tooltip: 'Hapus Staf',

                              onPressed: () {
                                _konfirmasiHapusKaryawan(staf);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ==================================
      // 3. TOMBOL TAMBAH KARYAWAN
      // ==================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahKaryawan,

        backgroundColor: const Color(0xFF1E3A8A),

        foregroundColor: Colors.white,

        icon: const Icon(Icons.person_add),

        label: const Text('Tambah Karyawan'),
      ),
    );
  }
}
