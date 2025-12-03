import 'package:browser_lite/features/files/presentation/pages/files_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/browser/presentation/pages/browser_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../theme/theme_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [BrowserPage(), FilesPage(), HistoryPage(), _SettingsPage()];
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: isDark ? Colors.blueGrey[200] : Colors.blueGrey[900],
        unselectedItemColor: isDark ? Colors.grey[700] : Colors.grey[400],
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              value: isDark,
              onChanged: (val) {
                ref.read(themeProvider.notifier).toggleTheme(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
