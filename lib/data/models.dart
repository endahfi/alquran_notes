String _stripHtml(String s) => s.replaceAll(RegExp(r'<[^>]*>'), '').trim();

/// Info singkat satu surat (dari GET /surat dan bagian atas GET /surat/{nomor}).
class Surah {
  const Surah({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.arti,
    required this.deskripsi,
  });

  final int nomor;
  final String nama; // nama Arab
  final String namaLatin;
  final int jumlahAyat;
  final String tempatTurun;
  final String arti;
  final String deskripsi;

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
        nomor: (j['nomor'] as num).toInt(),
        nama: (j['nama'] ?? '') as String,
        namaLatin: (j['namaLatin'] ?? '') as String,
        jumlahAyat: (j['jumlahAyat'] as num?)?.toInt() ?? 0,
        tempatTurun: (j['tempatTurun'] ?? '') as String,
        arti: (j['arti'] ?? '') as String,
        deskripsi: _stripHtml((j['deskripsi'] ?? '') as String),
      );
}

class Ayah {
  const Ayah({
    required this.nomorAyat,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
    this.audioUrl,
  });

  final int nomorAyat;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;
  final String? audioUrl;

  factory Ayah.fromJson(Map<String, dynamic> j) {
    // Audio berupa peta id qari -> url. "05" = Misyari Rasyid Al-Afasy.
    String? url;
    final audio = j['audio'];
    if (audio is Map && audio.isNotEmpty) {
      final v = audio['05'] ?? audio.values.first;
      if (v is String) url = v;
    }
    return Ayah(
      nomorAyat: (j['nomorAyat'] as num).toInt(),
      teksArab: (j['teksArab'] ?? '') as String,
      teksLatin: (j['teksLatin'] ?? '') as String,
      teksIndonesia: (j['teksIndonesia'] ?? '') as String,
      audioUrl: url,
    );
  }
}

class SurahDetail {
  const SurahDetail({required this.surah, required this.ayat});

  final Surah surah;
  final List<Ayah> ayat;

  factory SurahDetail.fromJson(Map<String, dynamic> j) => SurahDetail(
        surah: Surah.fromJson(j),
        ayat: (j['ayat'] as List)
            .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Referensi ayat yang sedang dibuka saat membuat catatan.
class AyahRef {
  const AyahRef({
    required this.surahNumber,
    required this.surahName,
    required this.ayah,
    required this.arabic,
    required this.translation,
  });

  final int surahNumber;
  final String surahName;
  final int ayah;
  final String arabic;
  final String translation;
}

/// Catatan. Bisa terkait ayat (surahNumber + ayahNumber terisi) atau bebas.
/// Teks Arab dan terjemahan disalin ke catatan supaya tetap terbaca offline.
class Note {
  const Note({
    this.id,
    this.surahNumber,
    this.ayahNumber,
    this.surahName,
    this.arabic,
    this.translation,
    this.title = '',
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int? surahNumber;
  final int? ayahNumber;
  final String? surahName;
  final String? arabic;
  final String? translation;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLinked => surahNumber != null && ayahNumber != null;

  Note copyWith({String? title, String? body, DateTime? updatedAt}) => Note(
        id: id,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        surahName: surahName,
        arabic: arabic,
        translation: translation,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'surah_number': surahNumber,
        'ayah_number': ayahNumber,
        'surah_name': surahName,
        'arabic': arabic,
        'translation': translation,
        'title': title,
        'body': body,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Note.fromMap(Map<String, Object?> m) => Note(
        id: m['id'] as int?,
        surahNumber: m['surah_number'] as int?,
        ayahNumber: m['ayah_number'] as int?,
        surahName: m['surah_name'] as String?,
        arabic: m['arabic'] as String?,
        translation: m['translation'] as String?,
        title: (m['title'] as String?) ?? '',
        body: (m['body'] as String?) ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}
