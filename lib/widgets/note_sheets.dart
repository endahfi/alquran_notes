import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alquran_notes/core/theme.dart';
import 'package:alquran_notes/data/models.dart';
import 'package:alquran_notes/providers/app_providers.dart';
import 'package:alquran_notes/widgets/note_card.dart';

/// Editor catatan. Beri [note] untuk mengubah, atau [ayahRef] untuk membuat
/// catatan baru yang terkait ayat. Tanpa keduanya = catatan bebas.
Future<void> showNoteEditor(
  BuildContext context, {
  Note? note,
  AyahRef? ayahRef,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => NoteEditor(note: note, ayahRef: ayahRef),
  );
}

/// Daftar catatan untuk satu ayat.
Future<void> showAyahNotesSheet(BuildContext context, AyahRef ayahRef) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AyahNotesSheet(ayahRef: ayahRef),
  );
}

class AyahNotesSheet extends ConsumerWidget {
  const AyahNotesSheet({super.key, required this.ayahRef});

  final AyahRef ayahRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
    final notes = all
        .where(
          (n) =>
              n.surahNumber == ayahRef.surahNumber &&
              n.ayahNumber == ayahRef.ayah,
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan QS. ${ayahRef.surahName}: ${ayahRef.ayah}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (notes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada catatan untuk ayat ini.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final n in notes)
                    NoteCard(
                      note: n,
                      showRef: false,
                      onTap: () => showNoteEditor(context, note: n),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: () => showNoteEditor(context, ayahRef: ayahRef),
            icon: const Icon(Icons.add),
            label: const Text('Tambah catatan'),
          ),
        ],
      ),
    );
  }
}

class NoteEditor extends ConsumerStatefulWidget {
  const NoteEditor({super.key, this.note, this.ayahRef});

  final Note? note;
  final AyahRef? ayahRef;

  @override
  ConsumerState<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  late final TextEditingController _title =
      TextEditingController(text: widget.note?.title ?? '');
  late final TextEditingController _body =
      TextEditingController(text: widget.note?.body ?? '');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final body = _body.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Isi catatan tidak boleh kosong.');
      return;
    }
    setState(() => _saving = true);
    final notifier = ref.read(notesProvider.notifier);
    final now = DateTime.now();
    final existing = widget.note;
    if (existing != null) {
      await notifier.edit(
        existing.copyWith(title: _title.text.trim(), body: body, updatedAt: now),
      );
    } else {
      final r = widget.ayahRef;
      await notifier.add(
        Note(
          surahNumber: r?.surahNumber,
          ayahNumber: r?.ayah,
          surahName: r?.surahName,
          arabic: r?.arabic,
          translation: r?.translation,
          title: _title.text.trim(),
          body: body,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text('Catatan yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(notesProvider.notifier).remove(widget.note!.id!);
    if (mounted) Navigator.of(context).pop();
  }

  Widget? _ayahContext() {
    String? label;
    String? arab;
    String? trans;
    final n = widget.note;
    final r = widget.ayahRef;
    if (n != null && n.isLinked) {
      label = 'QS. ${n.surahName}: ${n.ayahNumber}';
      arab = n.arabic;
      trans = n.translation;
    } else if (n == null && r != null) {
      label = 'QS. ${r.surahName}: ${r.ayah}';
      arab = r.arabic;
      trans = r.translation;
    } else {
      return null;
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.goldDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          if (arab != null && arab.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: Text(
                arab,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: arabicStyle(20),
              ),
            ),
          if (trans != null && trans.isNotEmpty)
            Text(
              trans,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;
    final context0 = _ayahContext();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    editing ? 'Ubah catatan' : 'Catatan baru',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (editing)
                  IconButton(
                    onPressed: _delete,
                    tooltip: 'Hapus',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (context0 != null) context0,
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Judul (opsional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              autofocus: !editing,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'Tulis refleksi, pelajaran, atau pertanyaanmu...',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
