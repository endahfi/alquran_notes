import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alquran_notes/core/theme.dart';
import 'package:alquran_notes/providers/app_providers.dart';
import 'package:alquran_notes/widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nama kamu'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Contoh: Aisyah'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null) {
      ref.read(settingsProvider.notifier).setName(result.trim());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final noteCount = ref.watch(notesProvider).valueOrNull?.length ?? 0;
    final last = ref.watch(lastReadProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'Profil',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.greenSoft,
                child: Text(
                  settings.initials,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  settings.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editName(context, ref, settings.name),
                tooltip: 'Ubah nama',
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(label: 'Catatan', value: '$noteCount'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  label: 'Terakhir dibaca',
                  value: last == null
                      ? '-'
                      : '${last.surahName}:${last.ayah}',
                ),
              ),
            ],
          ),
          const SectionTitle('Tampilan bacaan'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: arabicStyle(settings.arabicSize),
                  ),
                ),
                Row(
                  children: [
                    const Text('Ukuran', style: TextStyle(color: AppColors.muted)),
                    Expanded(
                      child: Slider(
                        value: settings.arabicSize,
                        min: 20,
                        max: 44,
                        divisions: 12,
                        label: settings.arabicSize.round().toString(),
                        activeColor: AppColors.green,
                        onChanged: notifier.setArabicSize,
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tampilkan terjemahan'),
                  value: settings.showTranslation,
                  activeColor: AppColors.green,
                  onChanged: notifier.setShowTranslation,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tampilkan teks Latin'),
                  value: settings.showLatin,
                  activeColor: AppColors.green,
                  onChanged: notifier.setShowLatin,
                ),
              ],
            ),
          ),
          const SectionTitle('Tentang'),
          const Text(
            "Data Al-Qur'an (teks Arab, terjemahan, dan audio) berasal dari "
            'API eQuran.id, dengan sumber Kementerian Agama RI. '
            'Catatanmu disimpan di perangkat ini.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
