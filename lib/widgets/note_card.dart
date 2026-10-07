import 'package:flutter/material.dart';
import 'package:alquran_notes/core/format.dart';
import 'package:alquran_notes/core/theme.dart';
import 'package:alquran_notes/data/models.dart';
import 'package:alquran_notes/screens/reader_screen.dart';
import 'package:alquran_notes/widgets/note_sheets.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.showRef = true,
  });

  final Note note;
  final VoidCallback? onTap;
  final bool showRef;

  @override
  Widget build(BuildContext context) {
    final title = note.title.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap ?? () => showNoteEditor(context, note: note),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showRef && note.isLinked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => openReader(
                        context,
                        note.surahNumber!,
                        ayah: note.ayahNumber,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.menu_book_outlined,
                              size: 14,
                              color: AppColors.goldDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'QS. ${note.surahName}: ${note.ayahNumber}',
                              style: const TextStyle(
                                color: AppColors.goldDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                Text(
                  note.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: 10),
                Text(
                  formatDate(note.updatedAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
