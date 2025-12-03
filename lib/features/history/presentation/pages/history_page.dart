import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/history_providers.dart';
import '../../../browser/domain/entities/page_cache.dart';
import '../../../summary/domain/entities/summary.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          ToggleButtons(
            isSelected: [_tabIndex == 0, _tabIndex == 1],
            borderRadius: BorderRadius.circular(16),
            onPressed: (index) {
              setState(() {
                _tabIndex = index;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Pages'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Summaries'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _tabIndex == 0
                ? _PagesHistoryList()
                : _SummariesHistoryList(),
          ),
        ],
      ),
    );
  }
}

class _PagesHistoryList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPages = ref.watch(pageHistoryProvider);

    return asyncPages.when(
      data: (pages) {
        if (pages.isEmpty) {
          return const Center(child: Text('No pages visited yet'));
        }
        return ListView.builder(
          itemCount: pages.length,
          // separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, index) {
            final page = pages[index];
            return _PageTile(page: page);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _PageTile extends StatelessWidget {
  final PageCache page;
  const _PageTile({required this.page});

  @override
  Widget build(BuildContext context) {
    final dt = page.updatedAt;
    final dateStr =
        '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: GestureDetector(
        onDoubleTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(page.title ?? 'Page Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('URL: ${page.url}'),
                  const SizedBox(height: 8),
                  Text('Visited: $dateStr'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.public),
            title: Text(
              page.title?.isNotEmpty == true ? page.title! : page.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${page.url}\nLast visited: $dateStr',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // isThreeLine: true,
          ),
        ),
      ),
    );
  }
}

class _SummariesHistoryList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummaries = ref.watch(summaryHistoryProvider);

    return asyncSummaries.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return const Center(child: Text('No summaries yet'));
        }
        return ListView.builder(
          itemCount: summaries.length,
          // separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final summary = summaries[index];
            return _SummaryTile(summary: summary);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final Summary summary;
  const _SummaryTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final dt = summary.createdAt;
    final dateStr =
        '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final srcTypeLabel = summary.sourceType == 'file' ? 'File' : 'Web page';

    final textSnippet = summary.summaryText.length > 60
        ? '${summary.summaryText.substring(0, 60)}...'
        : summary.summaryText;

    final translationLangs = summary.translations.keys.toList();
    final translationLabel = translationLangs.isEmpty
        ? 'No translations'
        : 'Translations: ${translationLangs.map((e) => e.toUpperCase()).join(', ')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: GestureDetector(
        onDoubleTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('$srcTypeLabel Summary'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.summaryText),
                    if (summary.translations.isNotEmpty) ...[
                      const Divider(),
                      const Text(
                        'Translations:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...summary.translations.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('${e.key}: ${e.value}'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Created: $dateStr',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Card(
          child: ListTile(
            leading: Icon(
              summary.sourceType == 'file'
                  ? Icons.insert_drive_file
                  : Icons.public,
            ),
            title: Text(
              '$srcTypeLabel summary',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '$dateStr\n$textSnippet\n$translationLabel',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            // isThreeLine: true,
          ),
        ),
      ),
    );
  }
}
