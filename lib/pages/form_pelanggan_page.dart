import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/pelanggan.dart';
import '../helpers/database_helper.dart';

class FormPelangganPage extends StatefulWidget {
  final Pelanggan? pelanggan;

  const FormPelangganPage({super.key, this.pelanggan});

  @override
  State<FormPelangganPage> createState() => _FormPelangganPageState();
}

class _FormPelangganPageState extends State<FormPelangganPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _kodeController;
  late TextEditingController _namaController;
  late TextEditingController _nomorWaController;
  late TextEditingController _alamatController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();

    final isEdit = widget.pelanggan != null;

    final autoKode =
        'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    _kodeController = TextEditingController(
      text: isEdit ? widget.pelanggan!.kodePelanggan : autoKode,
    );

    _namaController = TextEditingController(
      text: isEdit ? widget.pelanggan!.namaPelanggan : '',
    );

    _nomorWaController = TextEditingController(
      text: isEdit ? widget.pelanggan!.nomorWa : '',
    );

    _alamatController = TextEditingController(
      text: isEdit ? widget.pelanggan!.alamat : '',
    );

    _latitudeController = TextEditingController(
      text: isEdit && widget.pelanggan!.latitude != null
          ? widget.pelanggan!.latitude.toString()
          : '',
    );

    _longitudeController = TextEditingController(
      text: isEdit && widget.pelanggan!.longitude != null
          ? widget.pelanggan!.longitude.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _nomorWaController.dispose();
    _alamatController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // Mengambil koordinat GPS perangkat
  Future<void> _ambilKoordinatGps() async {
    if (_isLoadingGps) return;

    setState(() {
      _isLoadingGps = true;
    });

    try {
      // Memeriksa layanan GPS
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _tampilkanPesan(
          'Layanan GPS belum aktif. Silakan aktifkan GPS Anda.',
          Colors.orange,
        );
        return;
      }

      // Memeriksa izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _tampilkanPesan('Izin akses lokasi ditolak.', Colors.red);
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _tampilkanPesan(
          'Izin lokasi ditolak permanen. '
          'Silakan buka pengaturan aplikasi.',
          Colors.red,
        );
        return;
      }

      // Mengambil koordinat posisi saat ini
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });

      _tampilkanPesan(
        'GPS berhasil diperoleh: '
        '(${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)})',
        const Color(0xFF0D9488),
      );
    } catch (e) {
      _tampilkanPesan('Gagal mengambil koordinat GPS: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGps = false;
        });
      }
    }
  }

  // Menampilkan SnackBar
  void _tampilkanPesan(String pesan, Color warna) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(pesan), backgroundColor: warna));
  }

  // Menyimpan data pelanggan ke SQLite
  Future<void> _simpanPelanggan() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.pelanggan != null;

    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final latText = _latitudeController.text.trim();
    final lngText = _longitudeController.text.trim();

    final double? lat = latText.isEmpty ? null : double.tryParse(latText);

    final double? lng = lngText.isEmpty ? null : double.tryParse(lngText);

    final pelangganBaru = Pelanggan(
      id: isEdit ? widget.pelanggan!.id : null,
      kodePelanggan: _kodeController.text.trim(),
      namaPelanggan: _namaController.text.trim(),
      nomorWa: _nomorWaController.text.trim(),
      alamat: _alamatController.text.trim(),
      latitude: lat,
      longitude: lng,
      createdAt: isEdit ? widget.pelanggan!.createdAt : now,
    );

    try {
      if (isEdit) {
        await DatabaseHelper.instance.updatePelanggan(pelangganBaru);
      } else {
        await DatabaseHelper.instance.insertPelanggan(pelangganBaru);
      }

      if (!mounted) return;

      _tampilkanPesan(
        isEdit
            ? 'Data pelanggan berhasil diperbarui!'
            : 'Pelanggan baru berhasil ditambahkan!',
        const Color(0xFF1E3A8A),
      );

      Navigator.pop(context, true);
    } catch (e) {
      _tampilkanPesan('Terjadi kesalahan saat menyimpan: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pelanggan != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Data Pelanggan' : 'Tambah Pelanggan Baru'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner informasi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rekam nomor WhatsApp untuk pengiriman '
                        'nota digital dan simpan titik koordinat '
                        'GPS untuk rute pengantaran pesanan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Kode pelanggan
              TextFormField(
                controller: _kodeController,
                decoration: const InputDecoration(
                  labelText: 'Kode Member / ID Pelanggan *',
                  hintText: 'Contoh: CUST-001',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kode pelanggan tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Nama pelanggan
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap Pelanggan *',
                  hintText: 'Contoh: Warung Berkah Ibu Rini',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama pelanggan wajib diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Nomor WhatsApp
              TextFormField(
                controller: _nomorWaController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Kontak WhatsApp *',
                  hintText: 'Contoh: 081234567890',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nomor WhatsApp wajib diisi';
                  }

                  final nomor = value.trim();

                  if (!RegExp(r'^[0-9]+$').hasMatch(nomor)) {
                    return 'Nomor WhatsApp harus berupa angka';
                  }

                  if (nomor.length < 9 || nomor.length > 15) {
                    return 'Nomor telepon tidak valid';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Alamat pelanggan
              TextFormField(
                controller: _alamatController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat Pengantaran *',
                  hintText: 'Contoh: Jl. Kayu Tangi 1 Jalur 2 No. 15',
                  prefixIcon: Icon(Icons.home_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alamat pelanggan wajib diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Bagian GPS
              Card(
                elevation: 1,
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF0D9488)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Titik Lokasi Pengantaran (GPS)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Ambil posisi saat ini jika Anda berada '
                        'di lokasi fisik rumah atau toko pelanggan:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tombol GPS
                      ElevatedButton.icon(
                        onPressed: _isLoadingGps ? null : _ambilKoordinatGps,
                        icon: _isLoadingGps
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          _isLoadingGps
                              ? 'Mengambil Koordinat GPS...'
                              : 'Ambil Koordinat GPS Saat Ini',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Input Latitude dan Longitude
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                hintText: '-3.298280',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }

                                final lat = double.tryParse(value.trim());

                                if (lat == null || lat < -90 || lat > 90) {
                                  return 'Latitude tidak valid';
                                }

                                return null;
                              },
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                hintText: '114.588820',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }

                                final lng = double.tryParse(value.trim());

                                if (lng == null || lng < -180 || lng > 180) {
                                  return 'Longitude tidak valid';
                                }

                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tombol simpan
              ElevatedButton(
                onPressed: _simpanPelanggan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isEdit ? 'Perbarui Data Pelanggan' : 'Simpan Pelanggan Baru',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
