import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alquran_notes/core/theme.dart';
import 'package:alquran_notes/data/models.dart';
import 'package:alquran_notes/providers/app_providers.dart';
import 'package:alquran_notes/widgets/note_sheets.dart';

class AyahTile extends StatelessWidget {
  const AyahTile({
    super.key,
    required this.surah,
    required this.ayah,
    required this.settings,
    required this.noteCount,
  });

  final Surah surah;
  final Ayah ayah;
  final Settings settings;
  final int noteCount;

  AyahRef get _ref => AyahRef(
        surahNumber: surah.nomor,
        surahName: surah.namaLatin,
        ayah: ayah.nomorAyat,
        arabic: ayah.teksArab,
        translation: ayah.teksIndonesia,
      );

  void _copy(BuildContext context) {
    final text =
        '${ayah.teksArab}\n\n${ayah.teksIndonesia}\n(QS. ${surah.namaLatin}: ${ayah.nomorAyat})';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ayat disalin')),
    );
  }

  void _openNotes(BuildContext context) {
    if (noteCount == 0) {
      showNoteEditor(context, ayahRef: _ref);
    } else {
      showAyahNotesSheet(context, _ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.greenSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${ayah.nomorAyat}',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _copy(context),
                tooltip: 'Salin',
                icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.muted),
              ),
              IconButton(
                onPressed: () => _openNotes(context),
                tooltip: 'Catatan',
                icon: Badge(
                  isLabelVisible: noteCount > 0,
                  label: Text('$noteCount'),
                  backgroundColor: AppColors.gold,
                  child: Icon(
                    noteCount > 0
                        ? Icons.edit_note_rounded
                        : Icons.note_add_outlined,
                    size: 22,
                    color: noteCount > 0 ? AppColors.gold : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Text(
              ayah.teksArab,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: arabicStyle(settings.arabicSize),
            ),
          ),
          if (settings.showLatin && ayah.teksLatin.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ayah.teksLatin,
              style: const TextStyle(
                color: AppColors.gold,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
          if (settings.showTranslation && ayah.teksIndonesia.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ayah.teksIndonesia,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
