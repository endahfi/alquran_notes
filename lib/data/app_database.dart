import 'package:path/path.dart' as p;
import 'package:alquran_notes/data/models.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite lokal: tabel `notes` (catatan) dan `api_cache` (cache respons API
/// supaya surat yang pernah dibuka bisa dibaca offline).
class AppDatabase {
  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'quran_notes.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah_number INTEGER,
            ayah_number INTEGER,
            surah_name TEXT,
            arabic TEXT,
            translation TEXT,
            title TEXT NOT NULL DEFAULT '',
            body TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_notes_ayah ON notes (surah_number, ayah_number)',
        );
        await db.execute('''
          CREATE TABLE api_cache (
            cache_key TEXT PRIMARY KEY,
            json TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ---- Catatan ----

  Future<List<Note>> allNotes() async {
    final db = await _database;
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<int> insertNote(Note n) async {
    final db = await _database;
    return db.insert('notes', n.toMap());
  }

  Future<void> updateNote(Note n) async {
    final db = await _database;
    await db.update('notes', n.toMap(), where: 'id = ?', whereArgs: [n.id]);
  }

  Future<void> deleteNote(int id) async {
    final db = await _database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Cache API ----

  Future<String?> readCache(String key) async {
    final db = await _database;
    final rows = await db.query(
      'api_cache',
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['json'] as String;
  }

  Future<void> writeCache(String key, String json) async {
    final db = await _database;
    await db.insert(
      'api_cache',
      {'cache_key': key, 'json': json},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
