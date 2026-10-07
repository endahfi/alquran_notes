import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alquran_notes/core/theme.dart';
import 'package:alquran_notes/providers/app_providers.dart';
import 'package:alquran_notes/screens/home_screen.dart';
import 'package:alquran_notes/screens/notes_screen.dart';
import 'package:alquran_notes/screens/profile_screen.dart';
import 'package:alquran_notes/screens/quran_screen.dart';

class QuranNotesApp extends StatelessWidget {
  const QuranNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Qur'an & Catatan",
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(tabProvider);
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [
          HomeScreen(),
          QuranScreen(),
          NotesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: ref.read(tabProvider.notifier).go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: "Qur'an",
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label: 'Catatan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
