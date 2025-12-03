import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../providers/summary_provider.dart';
import '../../domain/entities/summary.dart';

const _languages = {'hi': 'Hindi', 'es': 'Spanish', 'fr': 'French'};

class SummaryPanel extends ConsumerStatefulWidget {
  final bool isSidePanel;
  const SummaryPanel({super.key, this.isSidePanel = false});

  @override
  ConsumerState<SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends ConsumerState<SummaryPanel> {
  bool _isOpen = false;
  String? _selectedLangCode;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.isSidePanel) {
      _isOpen = true;
    }
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(summaryProvider);

    if (widget.isSidePanel) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            left: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              title: const Text('AI Summary'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {},
              ),
            ),
            Expanded(child: _buildBody(summaryState)),
          ],
        ),
      );
    }

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final effectiveIsOpen = _isOpen && !isKeyboardOpen;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: effectiveIsOpen ? 400 : 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(blurRadius: 4, offset: Offset(0, -2))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _isOpen = !_isOpen);
            },
            child: Container(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                title: const Text('AI Summary'),
                trailing: IconButton(
                  icon: Icon(
                    effectiveIsOpen ? Icons.expand_more : Icons.expand_less,
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _isOpen = !_isOpen);
                  },
                ),
              ),
            ),
          ),
          if (effectiveIsOpen)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxHeight < 200) {
                      return const SizedBox();
                    }
                    return _buildBody(summaryState);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncValue<Summary?> summaryState) {
    return summaryState.when(
      data: (s) => s == null
          ? const Center(child: Text('Tap Summarize to generate summary'))
          : Column(
              children: [
                // Tabs for Summary / Translation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTabItem(0, 'Summary'),
                    const SizedBox(width: 16),
                    _buildTabItem(1, 'Translation'),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _SummaryView(
                        summary: s,
                        isPlaying: _isPlaying,
                        onPlay: () => _speak(s.summaryText, language: 'en-US'),
                        onStop: () => _stop(),
                      ),
                      _TranslationView(
                        summary: s,
                        selectedLangCode: _selectedLangCode,
                        onLanguageChanged: _onLanguageChanged,
                        isPlaying: _isPlaying,
                        isTtsLoading: _isTtsLoading,
                        onPlay: () => _speak(
                          s.translations[_selectedLangCode] ?? '',
                          language: _selectedLangCode,
                        ),
                        onStop: () => _stop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final isSelected = _currentPage == index;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        ),
      ),
    );
  }

  bool _isTtsLoading = false;

  Future<void> _speak(String text, {String? language}) async {
    if (text.isEmpty || _isTtsLoading) return;

    setState(() {
      _isTtsLoading = true;
    });

    try {
      // Map short codes to locales
      String locale = 'en-US';
      if (language != null) {
        switch (language) {
          case 'hi':
            locale = 'hi-IN';
            break;
          case 'es':
            locale = 'es-ES';
            break;
          case 'fr':
            locale = 'fr-FR';
            break;
          default:
            locale = language;
        }
      }

      await _flutterTts.setLanguage(locale);

      // Ensure state is still mounted before playing
      if (!mounted) return;

      setState(() {
        _isTtsLoading = false;
        _isPlaying = true;
      });

      await _flutterTts.speak(text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTtsLoading = false;
          _isPlaying = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    }
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _onLanguageChanged(String? langCode) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedLangCode = langCode;
    });

    if (langCode != null) {
      await _ensureTranslation(langCode);
    }
  }

  Future<void> _ensureTranslation(String langCode) async {
    final current = ref.read(summaryProvider).value;
    if (current == null) return;

    final hasTranslation = current.translations.containsKey(langCode);
    if (!hasTranslation) {
      await ref.read(summaryProvider.notifier).translate(langCode);
    }
  }
}

class _SummaryView extends StatelessWidget {
  final Summary summary;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  const _SummaryView({
    required this.summary,
    required this.isPlaying,
    required this.onPlay,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final reduction = summary.originalWordCount == 0
        ? 0
        : (100 - (summary.summaryWordCount / summary.originalWordCount * 100))
              .round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reduced $reduction% words',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const Spacer(),
            IconButton(
              icon: Icon(isPlaying ? Icons.stop : Icons.volume_up),
              tooltip: isPlaying ? 'Stop' : 'Read Aloud',
              onPressed: isPlaying ? onStop : onPlay,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: SingleChildScrollView(child: Text(summary.summaryText)),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: summary.summaryText));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Summary copied')));
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: () =>
                  Share.share(summary.summaryText, subject: 'Page Summary'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TranslationView extends StatelessWidget {
  final Summary summary;
  final String? selectedLangCode;
  final Function(String?) onLanguageChanged;
  final bool isPlaying;
  final bool _isTtsLoading;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  const _TranslationView({
    required this.summary,
    required this.selectedLangCode,
    required this.onLanguageChanged,
    required this.isPlaying,
    required bool isTtsLoading,
    required this.onPlay,
    required this.onStop,
  }) : _isTtsLoading = isTtsLoading;

  @override
  Widget build(BuildContext context) {
    final selectedLangName = selectedLangCode != null
        ? _languages[selectedLangCode] ?? selectedLangCode
        : null;
    final selectedTranslation = (selectedLangCode != null)
        ? summary.translations[selectedLangCode]
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButton<String>(
            hint: const Text('Select Language'),
            borderRadius: BorderRadius.circular(8),
            value: selectedLangCode,
            isExpanded: true,
            items: _languages.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: onLanguageChanged,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: selectedLangCode == null
              ? const Center(child: Text('Select a language to translate'))
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  child: selectedTranslation == null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text('Translating to $selectedLangName...'),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$selectedLangName translation:',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: _isTtsLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          isPlaying
                                              ? Icons.stop
                                              : Icons.volume_up,
                                        ),
                                  tooltip: isPlaying ? 'Stop' : 'Read Aloud',
                                  onPressed: isPlaying ? onStop : onPlay,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(selectedTranslation),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Copy',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: selectedTranslation),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Translation copied'),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  tooltip: 'Share',
                                  onPressed: () => Share.share(
                                    selectedTranslation,
                                    subject: 'Page Translation',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
        ),
      ],
    );
  }
}
