import 'dart:convert';

import 'package:alquran_notes/data/app_database.dart';
import 'package:alquran_notes/data/equran_api.dart';
import 'package:alquran_notes/data/models.dart';

/// Cache-first: isi Al-Qur'an tidak berubah, jadi setelah diunduh sekali
/// surat dibaca dari SQLite (cepat dan bisa offline).
class QuranRepository {
  QuranRepository(this._api, this._db);

  final EQuranApi _api;
  final AppDatabase _db;

  Future<List<Surah>> getSurahList() {
    return _load('surat_list', '/surat', (data) {
      return (data as List)
          .map((e) => Surah.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<SurahDetail> getSurah(int nomor) {
    return _load('surat_$nomor', '/surat/$nomor', (data) {
      return SurahDetail.fromJson(data as Map<String, dynamic>);
    });
  }

  Future<T> _load<T>(
    String key,
    String path,
    T Function(dynamic data) parse,
  ) async {
    final cached = await _db.readCache(key);
    if (cached != null) {
      try {
        return parse((jsonDecode(cached) as Map<String, dynamic>)['data']);
      } catch (_) {
        // Cache rusak atau format lama: abaikan dan unduh ulang.
      }
    }
    final body = await _api.get(path);
    final result = parse((jsonDecode(body) as Map<String, dynamic>)['data']);
    // Disimpan hanya setelah berhasil di-parse.
    await _db.writeCache(key, body);
    return result;
  }
}
