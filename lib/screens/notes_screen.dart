import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alquran_notes/core/theme.dart';
import 'package:alquran_notes/data/models.dart';
import 'package:alquran_notes/providers/app_providers.dart';
import 'package:alquran_notes/widgets/common.dart';
import 'package:alquran_notes/widgets/note_card.dart';
import 'package:alquran_notes/widgets/note_sheets.dart';

enum _Filter { all, ayah, free }

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  bool _matches(Note n) {
    switch (_filter) {
      case _Filter.ayah:
        if (!n.isLinked) return false;
      case _Filter.free:
        if (n.isLinked) return false;
      case _Filter.all:
        break;
    }
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return n.title.toLowerCase().contains(q) ||
        n.body.toLowerCase().contains(q) ||
        (n.surahName ?? '').toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNoteEditor(context),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Catatan baru'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Catatan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: const InputDecoration(
                  hintText: 'Cari catatan',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Wrap(
                spacing: 8,
                children: [
                  _chip('Semua', _Filter.all),
                  _chip('Per ayat', _Filter.ayah),
                  _chip('Bebas', _Filter.free),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  message: 'Catatan gagal dimuat.',
                  onRetry: () => ref.invalidate(notesProvider),
                ),
                data: (all) {
                  if (all.isEmpty) {
                    return const EmptyState(
                      icon: Icons.edit_note_rounded,
                      title: 'Belum ada catatan',
                      subtitle:
                          'Buka sebuah surat lalu ketuk ikon catatan pada ayat, atau buat catatan bebas.',
                    );
                  }
                  final list = all.where(_matches).toList();
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off,
                      title: 'Tidak ada yang cocok',
                      subtitle: 'Coba kata kunci atau filter lain.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _dismissible(list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _Filter value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.greenSoft,
      side: const BorderSide(color: AppColors.border),
    );
  }

  Widget _dismissible(Note n) {
    return Dismissible(
      key: ValueKey('note_${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        final notifier = ref.read(notesProvider.notifier);
        notifier.remove(n.id!);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Catatan dihapus'),
              action: SnackBarAction(
                label: 'Urungkan',
                onPressed: () => notifier.add(n),
              ),
            ),
          );
      },
      child: NoteCard(note: n),
    );
  }
}
