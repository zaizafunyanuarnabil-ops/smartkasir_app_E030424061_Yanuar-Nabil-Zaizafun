import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kelola_karyawan_page.dart';
import 'kelola_pelanggan_page.dart';

class ProfilTokoPage extends StatefulWidget {
  const ProfilTokoPage({super.key});

  @override
  State<ProfilTokoPage> createState() => _ProfilTokoPageState();
}

class _ProfilTokoPageState extends State<ProfilTokoPage> {
  // Controller identitas toko
  final _namaTokoController = TextEditingController();
  final _alamatController = TextEditingController();
  final _noWaController = TextEditingController();
  final _footerController = TextEditingController();

  // Validasi formulir
  final _formKey = GlobalKey<FormState>();

  // Status tombol simpan
  bool _sedangMenyimpan = false;
  bool _sedangMemuat = true;

  // Kasir aktif
  String _activeCashierName = 'Belum Ditentukan';

  // Warna tema SmartKasir
  static const Color _warnaUtama = Color(0xFF1E3A8A);
  static const Color _warnaBackground = Color(0xFFF8FAFC);
  static const Color _warnaBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _muatProfilToko();
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _alamatController.dispose();
    _noWaController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  // =========================================================
  // MEMUAT DATA PROFIL TOKO
  // =========================================================
  Future<void> _muatProfilToko() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _namaTokoController.text =
            prefs.getString('nama_toko') ?? 'SmartKasir Poliban';

        _alamatController.text =
            prefs.getString('alamat_toko') ??
            'Jl. Brigjend H. Hasan Basry, Banjarmasin';

        _noWaController.text = prefs.getString('no_wa') ?? '081234567890';

        _footerController.text = prefs.getString('footer_struk') ?? 'Terima Kasih Atas Kunjungan Anda! Barang yang sudah dibeli tidak dapat ditukar.';

        _activeCashierName =
            prefs.getString('active_cashier_name') ?? 'Belum Ditentukan';

        _sedangMemuat = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sedangMemuat = false;
      });

      _tampilkanPesan('Gagal memuat profil toko: $e');
    }
  }

  // =========================================================
  // MENYIMPAN PROFIL TOKO
  // =========================================================
  Future<void> _simpanProfilToko() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _sedangMenyimpan = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('nama_toko', _namaTokoController.text.trim());

      await prefs.setString('alamat_toko', _alamatController.text.trim());

      await prefs.setString('no_wa', _noWaController.text.trim());

      await prefs.setString('footer_struk', _footerController.text.trim());

      if (!mounted) return;

      _tampilkanPesan(
        'Identitas toko berhasil diperbarui!',
        warna: Colors.green.shade700,
      );
    } catch (e) {
      if (!mounted) return;

      _tampilkanPesan(
        'Gagal menyimpan pengaturan: $e',
        warna: Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() {
          _sedangMenyimpan = false;
        });
      }
    }
  }

  // =========================================================
  // SNACKBAR
  // =========================================================
  void _tampilkanPesan(String pesan, {Color? warna}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: warna ?? _warnaUtama,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================================
  // MEMBUKA KELOLA KARYAWAN
  // =========================================================
  Future<void> _bukaKelolaKaryawan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KelolaKaryawanPage()),
    );

    if (!mounted) return;

    await _muatProfilToko();
  }

  // =========================================================
  // MEMBUKA DATA PELANGGAN
  // =========================================================
  Future<void> _bukaKelolaPelanggan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KelolaPelangganPage()),
    );
  }

  // =========================================================
  // FIELD INPUT
  // =========================================================
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _warnaUtama),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _warnaBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _warnaUtama, width: 2),
        ),
      ),
    );
  }

  // =========================================================
  // KARTU KASIR AKTIF
  // =========================================================
  Widget _buildKartuKasir() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _warnaBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: _warnaUtama,
            child: Icon(Icons.storefront, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KASIR AKTIF SHIFT INI',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _activeCashierName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _bukaKelolaKaryawan,
            icon: const Icon(Icons.people_outline, size: 17),
            label: const Text('Kelola'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _warnaUtama,
              side: const BorderSide(color: _warnaUtama),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MENU KELOLA PELANGGAN
  // =========================================================
  Widget _buildMenuPelanggan() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _warnaBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF0D9488),
          child: Icon(Icons.people_alt, color: Colors.white),
        ),
        title: const Text(
          'Data Pelanggan & Lokasi GPS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: const Text(
          'Kelola member CRM dan navigasi rute pengantaran',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: _warnaUtama),
        onTap: _bukaKelolaPelanggan,
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warnaBackground,
      appBar: AppBar(
        title: const Text(
          'Profil & Pengaturan Toko',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _warnaUtama,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: _sedangMemuat
          ? const Center(child: CircularProgressIndicator(color: _warnaUtama))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // KASIR AKTIF
                    _buildKartuKasir(),

                    const SizedBox(height: 12),

                    // KELOLA PELANGGAN
                    _buildMenuPelanggan(),

                    const SizedBox(height: 24),

                    // JUDUL FORM
                    const Text(
                      'IDENTITAS USAHA & STRUK KASIR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _warnaUtama,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Atur informasi toko yang akan digunakan pada sistem kasir dan nota transaksi.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                    const SizedBox(height: 16),

                    // NAMA TOKO
                    _buildInput(
                      controller: _namaTokoController,
                      label: 'Nama Toko / Usaha',
                      icon: Icons.store,
                      hint: 'Masukkan nama toko',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama toko tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // ALAMAT TOKO
                    _buildInput(
                      controller: _alamatController,
                      label: 'Alamat Toko',
                      icon: Icons.location_on_outlined,
                      hint: 'Masukkan alamat toko',
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Alamat toko tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // NOMOR WHATSAPP
                    _buildInput(
                      controller: _noWaController,
                      label: 'Nomor WhatsApp / Kontak Toko',
                      icon: Icons.phone_outlined,
                      hint: 'Contoh: 081234567890',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nomor kontak toko tidak boleh kosong';
                        }

                        if (value.trim().length < 8) {
                          return 'Nomor kontak terlalu pendek';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // FOOTER STRUK
                    _buildInput(
                      controller: _footerController,
                      label: 'Catatan Kaki Struk (Footer Nota)',
                      icon: Icons.receipt_outlined,
                      hint: 'Terima kasih atas kunjungan Anda!',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Catatan struk tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // TOMBOL SIMPAN
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sedangMenyimpan ? null : _simpanProfilToko,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _warnaUtama,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _sedangMenyimpan
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _sedangMenyimpan
                              ? 'Menyimpan Pengaturan...'
                              : 'Simpan Profil Toko',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // INFO FOOTER
                    const Center(
                      child: Text(
                        'SmartKasir • Pengaturan Toko',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
