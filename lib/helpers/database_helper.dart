import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/produk.dart';
import '../models/karyawan.dart';
import '../models/pelanggan.dart';

class DatabaseHelper {
  // Singleton Pattern
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // Getter koneksi database
  Future<Database> get database async {
    if (_database != null) {
      await _seedProdukAwal(_database!);
      return _database!;
    }

    _database = await _initDB('smartkasir.db');
    await _seedProdukAwal(_database!);

    return _database!;
  }

  // Inisialisasi database SQLite (Android dan Web)
  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;

      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _createDB,
          onUpgrade: _onUpgradeDB,
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final dbFilePath = join(dbPath, filePath);

      return await openDatabase(
        dbFilePath,
        version: 3,
        onCreate: _createDB,
        onUpgrade: _onUpgradeDB,
      );
    }
  }

  // Seeder produk awal
  Future<void> _seedProdukAwal(Database db) async {
    try {
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM produk'),
          ) ??
          0;

      if (count == 0) {
        for (final produk in produkAwalSQLite) {
          await db.insert('produk', produk.toMap());
        }
      }
    } catch (_) {
      // Mengabaikan jika tabel produk belum terbentuk
    }
  }

  // Membuat tabel database saat instalasi pertama
  Future<void> _createDB(Database db, int version) async {
    // Tabel Produk (Modul M11)
    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_produk TEXT UNIQUE,
        nama_produk TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok INTEGER NOT NULL,
        gambar_path TEXT,
        diskon_persen INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Tabel Karyawan (Modul M12)
    await db.execute('''
      CREATE TABLE karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_karyawan TEXT NOT NULL,
        pin TEXT NOT NULL,
        peran TEXT NOT NULL
      )
    ''');

    // Tabel Pelanggan (Modul M13)
    await db.execute('''
      CREATE TABLE pelanggan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_pelanggan TEXT UNIQUE NOT NULL,
        nama_pelanggan TEXT NOT NULL,
        nomor_wa TEXT NOT NULL,
        alamat TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL
      )
    ''');

    // Seeder 6 produk bawaan
    await _seedProdukAwal(db);

    // Seeder karyawan default
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Ahmad Kasir', '1234', 'Kasir')
    ''');

    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Siti Supervisor', '8888', 'Manajer')
    ''');

    // Seeder pelanggan awal
    await db.rawInsert('''
      INSERT INTO pelanggan (
        kode_pelanggan,
        nama_pelanggan,
        nomor_wa,
        alamat,
        latitude,
        longitude,
        created_at
      )
      VALUES (
        'CUST-001',
        'Warung Bu Siti',
        '081234567890',
        'Jl. Hasan Basri No. 12, Banjarmasin',
        -3.298280,
        114.588820,
        '2026-11-01 09:00:00'
      )
    ''');

    await db.rawInsert('''
      INSERT INTO pelanggan (
        kode_pelanggan,
        nama_pelanggan,
        nomor_wa,
        alamat,
        latitude,
        longitude,
        created_at
      )
      VALUES (
        'CUST-002',
        'Budi Santoso',
        '085712345678',
        'Jl. Kayu Tangi II No. 45, Banjarmasin',
        -3.295410,
        114.582150,
        '2026-11-02 10:30:00'
      )
    ''');
  }

  // Migrasi database ketika versi database meningkat
  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    // Memastikan tabel produk tersedia
    await db.execute('''
      CREATE TABLE IF NOT EXISTS produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_produk TEXT UNIQUE,
        nama_produk TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok INTEGER NOT NULL,
        gambar_path TEXT,
        diskon_persen INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Memastikan produk awal tersedia
    await _seedProdukAwal(db);

    // Migrasi tabel karyawan ke versi 2
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS karyawan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_karyawan TEXT NOT NULL,
          pin TEXT NOT NULL,
          peran TEXT NOT NULL
        )
      ''');

      final countKaryawan =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM karyawan'),
          ) ??
          0;

      if (countKaryawan == 0) {
        await db.rawInsert('''
          INSERT INTO karyawan (nama_karyawan, pin, peran)
          VALUES ('Ahmad Kasir', '1234', 'Kasir')
        ''');

        await db.rawInsert('''
          INSERT INTO karyawan (nama_karyawan, pin, peran)
          VALUES ('Siti Supervisor', '8888', 'Manajer')
        ''');
      }
    }

    // Migrasi tabel pelanggan ke versi 3
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pelanggan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kode_pelanggan TEXT UNIQUE NOT NULL,
          nama_pelanggan TEXT NOT NULL,
          nomor_wa TEXT NOT NULL,
          alamat TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          created_at TEXT NOT NULL
        )
      ''');

      final countPelanggan =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM pelanggan'),
          ) ??
          0;

      if (countPelanggan == 0) {
        await db.rawInsert('''
          INSERT INTO pelanggan (
            kode_pelanggan,
            nama_pelanggan,
            nomor_wa,
            alamat,
            latitude,
            longitude,
            created_at
          )
          VALUES (
            'CUST-001',
            'Warung Bu Siti',
            '081234567890',
            'Jl. Hasan Basri No. 12, Banjarmasin',
            -3.298280,
            114.588820,
            '2026-11-01 09:00:00'
          )
        ''');

        await db.rawInsert('''
          INSERT INTO pelanggan (
            kode_pelanggan,
            nama_pelanggan,
            nomor_wa,
            alamat,
            latitude,
            longitude,
            created_at
          )
          VALUES (
            'CUST-002',
            'Budi Santoso',
            '085712345678',
            'Jl. Kayu Tangi II No. 45, Banjarmasin',
            -3.295410,
            114.582150,
            '2026-11-02 10:30:00'
          )
        ''');
      }
    }
  }

  // ==========================================
  // CRUD PELANGGAN (MODUL M13)
  // ==========================================

  // CREATE: Menyimpan pelanggan baru
  Future<int> insertPelanggan(Pelanggan pelanggan) async {
    final db = await instance.database;
    return await db.insert('pelanggan', pelanggan.toMap());
  }

  // READ: Mengambil seluruh data pelanggan
  Future<List<Pelanggan>> getAllPelanggan() async {
    final db = await instance.database;

    final result = await db.query('pelanggan', orderBy: 'id DESC');

    return result.map((json) => Pelanggan.fromMap(json)).toList();
  }

  // SEARCH: Mencari pelanggan berdasarkan nama, WA, atau kode
  Future<List<Pelanggan>> searchPelanggan(String keyword) async {
    final db = await instance.database;

    final result = await db.query(
      'pelanggan',
      where:
          'nama_pelanggan LIKE ? OR nomor_wa LIKE ? OR kode_pelanggan LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
      orderBy: 'id DESC',
    );

    return result.map((json) => Pelanggan.fromMap(json)).toList();
  }

  // UPDATE: Memperbarui data pelanggan
  Future<int> updatePelanggan(Pelanggan pelanggan) async {
    final db = await instance.database;

    return await db.update(
      'pelanggan',
      pelanggan.toMap(),
      where: 'id = ?',
      whereArgs: [pelanggan.id],
    );
  }

  // DELETE: Menghapus pelanggan berdasarkan ID
  Future<int> deletePelanggan(int id) async {
    final db = await instance.database;

    return await db.delete('pelanggan', where: 'id = ?', whereArgs: [id]);
  }

  // COUNT: Menghitung jumlah pelanggan
  Future<int> countPelanggan() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT COUNT(*) as total FROM pelanggan');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==========================================
  // CRUD KARYAWAN (MODUL M12)
  // ==========================================

  // CREATE: Menambahkan karyawan
  Future<int> insertKaryawan(Karyawan karyawan) async {
    final db = await instance.database;
    return await db.insert('karyawan', karyawan.toMap());
  }

  // READ: Mengambil seluruh data karyawan
  Future<List<Karyawan>> getAllKaryawan() async {
    final db = await instance.database;

    final result = await db.query('karyawan', orderBy: 'id ASC');

    return result.map((json) => Karyawan.fromMap(json)).toList();
  }

  // UPDATE: Memperbarui data karyawan
  Future<int> updateKaryawan(Karyawan karyawan) async {
    final db = await instance.database;

    return await db.update(
      'karyawan',
      karyawan.toMap(),
      where: 'id = ?',
      whereArgs: [karyawan.id],
    );
  }

  // DELETE: Menghapus karyawan
  Future<int> deleteKaryawan(int id) async {
    final db = await instance.database;

    return await db.delete('karyawan', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // CRUD PRODUK (MODUL M11)
  // ==========================================

  // CREATE: Menambahkan produk
  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;
    return await db.insert('produk', produk.toMap());
  }

  // READ: Mengambil seluruh produk
  Future<List<Produk>> getAllProduk() async {
    final db = await instance.database;

    final result = await db.query('produk', orderBy: 'id DESC');

    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // FILTER: Mengambil produk berdasarkan kategori
  Future<List<Produk>> getProdukByKategori(String kategori) async {
    final db = await instance.database;

    if (kategori == 'Semua') {
      return await getAllProduk();
    }

    final result = await db.query(
      'produk',
      where: 'kategori = ?',
      whereArgs: [kategori],
      orderBy: 'id DESC',
    );

    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // SEARCH: Mencari produk berdasarkan nama
  Future<List<Produk>> searchProduk(String keyword) async {
    final db = await instance.database;

    final result = await db.query(
      'produk',
      where: 'nama_produk LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'id DESC',
    );

    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // UPDATE: Memperbarui produk
  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;

    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  // DELETE: Menghapus produk
  Future<int> deleteProduk(int id) async {
    final db = await instance.database;

    return await db.delete('produk', where: 'id = ?', whereArgs: [id]);
  }

  // COUNT: Menghitung jumlah produk
  Future<int> countProduk() async {
    final db = await instance.database;

    final result = await db.rawQuery('SELECT COUNT(*) as total FROM produk');

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
