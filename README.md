# Qur'an & Catatan

Aplikasi Flutter untuk membaca Al-Qur'an (terjemahan Indonesia) dan menulis catatan pribadi per ayat.
Data dari [API eQuran.id v2](https://equran.id/apidev/v2) (sumber: Kementerian Agama RI).

## Menjalankan

```bash
flutter create --project-name quran_notes .   
flutter pub get
flutter run
```

Jika `flutter create` menimpa `lib/main.dart`, kembalikan dari zip ini (isi `lib/` dan `pubspec.yaml` adalah yang dipakai).

**Android rilis:** tambahkan izin internet di `android/app/src/main/AndroidManifest.xml` (di dalam `<manifest>`, di atas `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Mode debug sudah punya izin ini, tapi build rilis tidak.

## Arsitektur

```
lib/
  core/        tema (warna, font) dan format tanggal
  data/        models, klien API, SQLite, repository (cache-first)
  providers/   Riverpod: data_providers (API/DB) dan app_providers (state aplikasi)
  screens/     home, quran, reader, notes, profile
  widgets/     ayah_tile, note_card, note_sheets (editor), common
```

### State management: Riverpod (tanpa code generation)

- `FutureProvider` / `FutureProvider.family`: daftar surat dan detail surat (loading, error, dan data ditangani oleh `AsyncValue.when`).
- `AsyncNotifier`: `notesProvider` (catatan, CRUD ke SQLite).
- `Notifier`: pengaturan, terakhir dibaca, tab aktif.
- `Provider` turunan: `notedAyahProvider` menghitung jumlah catatan per ayat dari daftar catatan, sehingga penanda di pembaca otomatis ikut berubah.

### Catatan

- Disimpan lokal di SQLite (`sqflite`), tidak perlu akun.
- Dua jenis: **terkait ayat** (`surah_number` + `ayah_number` terisi) dan **bebas** (kosong).
- Teks Arab dan terjemahan ayat disalin ke catatan, jadi catatan tetap utuh di daftar Catatan walau offline.
- Satu ayat boleh punya banyak catatan.

### Cache API

`QuranRepository` memakai pola cache-first: respons JSON disimpan di tabel `api_cache` setelah berhasil di-parse. Surat yang pernah dibuka bisa dibaca offline.

## Endpoint yang dipakai

| Endpoint | Fungsi |
|---|---|
| `GET /api/v2/surat` | Daftar 114 surat |
| `GET /api/v2/surat/{nomor}` | Detail surat, ayat, dan audio per ayat |

Respons dibungkus `{ code, message, data }`. Nama field yang dibaca model: `nomor`, `nama`, `namaLatin`, `jumlahAyat`, `tempatTurun`, `arti`, `deskripsi`; per ayat: `nomorAyat`, `teksArab`, `teksLatin`, `teksIndonesia`, `audio`.

> Nama field disusun dari dokumentasi dan SDK resmi, belum diuji terhadap respons langsung. Jika ada yang kosong atau error saat dijalankan pertama kali, cek `lib/data/models.dart` terhadap JSON asli (`curl https://equran.id/api/v2/surat/1`).


## Catatan versi

Kode ditulis untuk Flutter 3.24 ke atas dan flutter_riverpod 2.x. Bila versi Flutter terbaru memberi peringatan deprecation (misalnya `activeColor` pada `SwitchListTile`), itu hanya peringatan dan mudah disesuaikan.
