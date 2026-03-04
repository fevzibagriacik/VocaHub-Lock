import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vocat_words.db');
    return _database!;
  }

  Future<void> replaceDatabaseWithNewCSV(String filePath) async {
    final db = await instance.database;

    // 1. Mevcut tablodaki tüm kelimeleri temizle
    await db.delete('Kelimeler');

    // 2. Yeni dosyayı telefondan oku
    final file = File(filePath);
    final csvData = await file.readAsString();
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);

    // 3. Yeni verileri veritabanına topluca yaz
    Batch batch = db.batch();
    for (var i = 1; i < csvTable.length; i++) {
      var row = csvTable[i];

      String w = row.isNotEmpty ? row[0].toString() : "";
      String m = row.length > 1 ? row[1].toString() : "";
      // Eğer formatında ipucu 4. indekste (E sütunu) ise:
      String s = row.length > 4 ? row[4].toString() : "Yok";

      if (w.isNotEmpty) {
        batch.insert('Kelimeler', {
          'W': w,
          'M': m,
          'S': s,
        });
      }
    }
    await batch.commit(noResult: true);
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Kelimeler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        W TEXT,
        M TEXT,
        S TEXT
      )
    ''');
  }

  // CSV'yi okuyup veritabanına aktaran fonksiyon
  Future<void> loadCSVToDatabase() async {
    final db = await instance.database;

    // Tabloda veri var mı diye kontrol ediyoruz (her açılışta tekrar yüklemesin diye)
    var count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Kelimeler'));
    if (count != null && count > 0) {
      return; // Veritabanı zaten dolu, işlemi iptal et
    }

    // assets içindeki csv dosyasını okuyoruz
    final csvData = await rootBundle.loadString('assets/kelimeler.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);

    // Verileri topluca eklemek için batch kullanıyoruz (çok daha hızlıdır)
    Batch batch = db.batch();

    // İlk satır (index 0) başlıklar olduğu için döngüye 1'den başlıyoruz
    for (var i = 1; i < csvTable.length; i++) {
      var row = csvTable[i];

      // Sütun verilerini güvenli bir şekilde alıyoruz
      String w = row.isNotEmpty ? row[0].toString() : "";
      String m = row.length > 1 ? row[1].toString() : "";
      String s = row.length > 4 ? row[4].toString() : "Yok";

      if (w.isNotEmpty) {
        batch.insert('Kelimeler', {
          'W': w,
          'M': m,
          'S': s,
        });
      }
    }
    await batch.commit(noResult: true);
  }

  // Rastgele tek bir kelime çeken fonksiyon
  Future<Map<String, dynamic>?> getRandomWord() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT * FROM Kelimeler ORDER BY RANDOM() LIMIT 1');
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}