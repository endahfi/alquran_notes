import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alquran_notes/core/theme.dart';
import 'package:alquran_notes/data/models.dart';
import 'package:alquran_notes/providers/app_providers.dart';
import 'package:alquran_notes/screens/reader_screen.dart';
import 'package:alquran_notes/widgets/common.dart';
import 'package:alquran_notes/widgets/note_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final last = ref.watch(lastReadProvider);
    final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
    final recent = notes.take(2).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.greenSoft,
                child: Text(
                  settings.initials,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Assalamu'alaikum,",
                      style: TextStyle(color: AppColors.muted),
                    ),
                    Text(
                      settings.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _LastReadCard(last: last),
          const SizedBox(height: 16),
          const _DailyVerseCard(),
          const SizedBox(height: 16),
          const _QuickActions(),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionTitle(
              'Catatan terbaru',
              trailing: TextButton(
                onPressed: () => ref.read(tabProvider.notifier).go(2),
                child: const Text('Lihat semua'),
              ),
            ),
            for (final n in recent) NoteCard(note: n),
          ],
        ],
      ),
    );
  }
}

class _LastReadCard extends StatelessWidget {
  const _LastReadCard({required this.last});

  final LastRead? last;

  @override
  Widget build(BuildContext context) {
    final lr = last;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Terakhir dibaca', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            lr == null
                ? 'Belum ada bacaan'
                : '${lr.surahName} • Ayat ${lr.ayah}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: lr?.progress ?? 0,
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              shape: const StadiumBorder(),
            ),
            onPressed: () => openReader(
              context,
              lr?.surahNumber ?? 1,
              ayah: lr?.ayah,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lr == null ? 'Mulai membaca' : 'Lanjutkan membaca'),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyVerseCard extends ConsumerWidget {
  const _DailyVerseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyVerseProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ayat hari ini', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ayat hari ini belum bisa dimuat. Periksa koneksi internet.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(dailyVerseProvider),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
            data: (v) => InkWell(
              onTap: () => openReader(
                context,
                v.surah.nomor,
                ayah: v.ayah.nomorAyat,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      v.ayah.teksArab,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: arabicStyle(26),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${v.ayah.teksIndonesia}"',
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'QS. ${v.surah.namaLatin}: ${v.ayah.nomorAyat}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.menu_book_outlined,
            label: "Baca Qur'an",
            background: AppColors.greenSoft,
            foreground: AppColors.green,
            onTap: () => ref.read(tabProvider.notifier).go(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.description_outlined,
            label: 'Catatan Saya',
            background: AppColors.goldSoft,
            foreground: AppColors.goldDark,
            onTap: () => ref.read(tabProvider.notifier).go(2),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground),
              const SizedBox(height: 28),
              Text(
                label,
                style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
