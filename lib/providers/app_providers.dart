import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alquran_notes/data/models.dart';
import 'package:alquran_notes/providers/data_providers.dart';

// ---------------------------------------------------------------------------
// Tab aktif (dipakai tombol pintas di Beranda)
// ---------------------------------------------------------------------------

class TabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void go(int index) => state = index;
}

final tabProvider = NotifierProvider<TabNotifier, int>(TabNotifier.new);

// ---------------------------------------------------------------------------
// Pengaturan (disimpan di SharedPreferences)
// ---------------------------------------------------------------------------

class Settings {
  const Settings({
    this.name = '',
    this.arabicSize = 28,
    this.showLatin = false,
    this.showTranslation = true,
  });

  final String name;
  final double arabicSize;
  final bool showLatin;
  final bool showTranslation;

  String get displayName => name.trim().isEmpty ? 'Sahabat' : name.trim();

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Q';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Settings copyWith({
    String? name,
    double? arabicSize,
    bool? showLatin,
    bool? showTranslation,
  }) =>
      Settings(
        name: name ?? this.name,
        arabicSize: arabicSize ?? this.arabicSize,
        showLatin: showLatin ?? this.showLatin,
        showTranslation: showTranslation ?? this.showTranslation,
      );
}

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    final p = ref.watch(sharedPrefsProvider);
    return Settings(
      name: p.getString('name') ?? '',
      arabicSize: p.getDouble('arabic_size') ?? 28,
      showLatin: p.getBool('show_latin') ?? false,
      showTranslation: p.getBool('show_translation') ?? true,
    );
  }

  void setName(String v) {
    state = state.copyWith(name: v);
    ref.read(sharedPrefsProvider).setString('name', v);
  }

  void setArabicSize(double v) {
    state = state.copyWith(arabicSize: v);
    ref.read(sharedPrefsProvider).setDouble('arabic_size', v);
  }

  void setShowLatin(bool v) {
    state = state.copyWith(showLatin: v);
    ref.read(sharedPrefsProvider).setBool('show_latin', v);
  }

  void setShowTranslation(bool v) {
    state = state.copyWith(showTranslation: v);
    ref.read(sharedPrefsProvider).setBool('show_translation', v);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

// ---------------------------------------------------------------------------
// Terakhir dibaca
// ---------------------------------------------------------------------------

class LastRead {
  const LastRead({
    required this.surahNumber,
    required this.surahName,
    required this.ayah,
    required this.totalAyah,
  });

  final int surahNumber;
  final String surahName;
  final int ayah;
  final int totalAyah;

  double get progress =>
      totalAyah == 0 ? 0.0 : (ayah / totalAyah).clamp(0.0, 1.0).toDouble();
}

class LastReadNotifier extends Notifier<LastRead?> {
  @override
  LastRead? build() {
    final p = ref.watch(sharedPrefsProvider);
    final n = p.getInt('lr_surah');
    if (n == null) return null;
    return LastRead(
      surahNumber: n,
      surahName: p.getString('lr_name') ?? '',
      ayah: p.getInt('lr_ayah') ?? 1,
      totalAyah: p.getInt('lr_total') ?? 0,
    );
  }

  void save(LastRead v) {
    state = v;
    final p = ref.read(sharedPrefsProvider);
    p.setInt('lr_surah', v.surahNumber);
    p.setString('lr_name', v.surahName);
    p.setInt('lr_ayah', v.ayah);
    p.setInt('lr_total', v.totalAyah);
  }
}

final lastReadProvider =
    NotifierProvider<LastReadNotifier, LastRead?>(LastReadNotifier.new);

// ---------------------------------------------------------------------------
// Catatan (SQLite)
// ---------------------------------------------------------------------------

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() => ref.read(databaseProvider).allNotes();

  Future<void> _reload() async {
    state = AsyncData(await ref.read(databaseProvider).allNotes());
  }

  Future<void> add(Note n) async {
    await ref.read(databaseProvider).insertNote(n);
    await _reload();
  }

  Future<void> edit(Note n) async {
    await ref.read(databaseProvider).updateNote(n);
    await _reload();
  }

  /// Optimistis: daftar diperbarui sinkron dulu supaya Dismissible langsung
  /// hilang dari pohon widget, baru database dihapus.
  Future<void> remove(int id) async {
    final current = state.valueOrNull ?? const <Note>[];
    state = AsyncData(current.where((n) => n.id != id).toList());
    await ref.read(databaseProvider).deleteNote(id);
  }
}

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

/// Peta "surat:ayat" -> jumlah catatan, untuk penanda di pembaca.
final notedAyahProvider = Provider<Map<String, int>>((ref) {
  final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  final map = <String, int>{};
  for (final n in notes) {
    if (n.isLinked) {
      final k = '${n.surahNumber}:${n.ayahNumber}';
      map[k] = (map[k] ?? 0) + 1;
    }
  }
  return map;
});

// ---------------------------------------------------------------------------
// Ayat hari ini
// ---------------------------------------------------------------------------

/// (nomor surat, nomor ayat). Dipilih berdasarkan hari dalam setahun.
const dailyVerseRefs = <(int, int)>[
  (2, 152),
  (2, 186),
  (2, 255),
  (2, 286),
  (3, 139),
  (13, 28),
  (39, 53),
  (65, 3),
  (94, 5),
  (94, 6),
];

class DailyVerse {
  const DailyVerse({required this.surah, required this.ayah});
  final Surah surah;
  final Ayah ayah;
}

final dailyVerseProvider = FutureProvider<DailyVerse>((ref) async {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  final pick = dailyVerseRefs[dayOfYear % dailyVerseRefs.length];
  final detail = await ref.watch(surahDetailProvider(pick.$1).future);
  final ayah = detail.ayat.firstWhere(
    (a) => a.nomorAyat == pick.$2,
    orElse: () => detail.ayat.first,
  );
  return DailyVerse(surah: detail.surah, ayah: ayah);
});
