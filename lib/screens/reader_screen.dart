import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alquran_notes/core/theme.dart';
import 'package:alquran_notes/data/models.dart';
import 'package:alquran_notes/providers/app_providers.dart';
import 'package:alquran_notes/providers/data_providers.dart';
import 'package:alquran_notes/widgets/ayah_tile.dart';
import 'package:alquran_notes/widgets/common.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void openReader(BuildContext context, int surah, {int? ayah}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReaderScreen(surahNumber: surah, initialAyah: ayah),
    ),
  );
}

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.surahNumber, this.initialAyah});

  final int surahNumber;
  final int? initialAyah;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _itemController = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  SurahDetail? _detail;
  int _lastSaved = -1;

  @override
  void initState() {
    super.initState();
    _positions.itemPositions.addListener(_onScroll);
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  /// Item 0 = kepala surat, item k (k >= 1) = ayat ke-k.
  void _onScroll() {
    final d = _detail;
    if (d == null || d.ayat.isEmpty) return;
    final visible = _positions.itemPositions.value
        .where((p) => p.itemTrailingEdge > 0)
        .toList();
    if (visible.isEmpty) return;
    final first = visible.reduce((a, b) => a.index < b.index ? a : b);
    final ayah = first.index.clamp(1, d.ayat.length).toInt();
    if (ayah == _lastSaved) return;
    _lastSaved = ayah;
    ref.read(lastReadProvider.notifier).save(
          LastRead(
            surahNumber: d.surah.nomor,
            surahName: d.surah.namaLatin,
            ayah: ayah,
            totalAyah: d.ayat.length,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(surahDetailProvider(widget.surahNumber));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.maybeWhen(data: (d) => d.surah.namaLatin, orElse: () => 'Memuat...'),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          onRetry: () => ref.invalidate(surahDetailProvider(widget.surahNumber)),
        ),
        data: (d) {
          _detail = d;
          return _buildList(d);
        },
      ),
    );
  }

  Widget _buildList(SurahDetail d) {
    final settings = ref.watch(settingsProvider);
    final noted = ref.watch(notedAyahProvider);
    final start = (widget.initialAyah ?? 0).clamp(0, d.ayat.length).toInt();

    return ScrollablePositionedList.builder(
      itemScrollController: _itemController,
      itemPositionsListener: _positions,
      initialScrollIndex: start,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: d.ayat.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _SurahHeader(surah: d.surah);
        final a = d.ayat[i - 1];
        return AyahTile(
          surah: d.surah,
          ayah: a,
          settings: settings,
          noteCount: noted['${d.surah.nomor}:${a.nomorAyat}'] ?? 0,
        );
      },
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final showBismillah = surah.nomor != 1 && surah.nomor != 9;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            surah.nama,
            style: arabicStyle(34, color: Colors.white).copyWith(height: 1.6),
          ),
          Text(
            surah.namaLatin,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${surah.arti} • ${surah.tempatTurun} • ${surah.jumlahAyat} ayat',
            style: const TextStyle(color: Colors.white70),
          ),
          if (showBismillah) ...[
            const SizedBox(height: 12),
            Text(
              'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
              style: arabicStyle(24, color: AppColors.goldSoft),
            ),
          ],
        ],
      ),
    );
  }
}
