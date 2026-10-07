import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alquran_notes/data/app_database.dart';
import 'package:alquran_notes/data/equran_api.dart';
import 'package:alquran_notes/data/models.dart';
import 'package:alquran_notes/data/quran_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Di-override di main.dart setelah SharedPreferences siap.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override di main.dart'),
);

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final quranRepositoryProvider = Provider<QuranRepository>(
  (ref) => QuranRepository(EQuranApi(), ref.watch(databaseProvider)),
);

final surahListProvider = FutureProvider<List<Surah>>(
  (ref) => ref.watch(quranRepositoryProvider).getSurahList(),
);

final surahDetailProvider = FutureProvider.family<SurahDetail, int>(
  (ref, nomor) => ref.watch(quranRepositoryProvider).getSurah(nomor),
);
