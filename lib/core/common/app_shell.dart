import 'package:browser_lite/features/files/presentation/pages/files_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/browser/presentation/pages/browser_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../theme/theme_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final GlobalKey<BrowserPageState> _browserKey = GlobalKey<BrowserPageState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      BrowserPage(key: _browserKey),
      const FilesPage(),
      const HistoryPage(),
      const _SettingsPage(),
    ];
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (val.hasConfidenceRating && val.confidence > 0) {
              _processCommand(val.recognizedWords);
            }
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processCommand(String command) {
    final lowerCommand = command.toLowerCase();
    if (lowerCommand.contains('summarize tab') || lowerCommand.contains('summarise tab')) {
      _browserKey.currentState?.summarizeCurrentPage();
      _speech.stop();
      setState(() => _isListening = false);
    } else if (lowerCommand.contains('dark mode')) {
      ref.read(themeProvider.notifier).toggleTheme(true);
      _speech.stop();
      setState(() => _isListening = false);
    } else if (lowerCommand.contains('light mode')) {
      ref.read(themeProvider.notifier).toggleTheme(false);
      _speech.stop();
      setState(() => _isListening = false);
    }
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
      floatingActionButton: _selectedIndex == 0 // Only show on Browser tab
          ? FloatingActionButton(
              onPressed: _listen,
              backgroundColor: _isListening ? Colors.red : null,
              child: Icon(_isListening ? Icons.mic : Icons.mic_none),
            )
          : null,
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
