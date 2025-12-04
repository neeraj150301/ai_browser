import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:dio/dio.dart';
import '../widgets/web_browser_view.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../presentation/providers/page_cache_provider.dart';
import '../../domain/entities/browser_tab.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../files/presentation/providers/file_provider.dart';
import '../../../summary/presentation/providers/summary_provider.dart';
import '../../../summary/presentation/widgets/summary_panel.dart';
import '../providers/tab_manager.dart';

class BrowserPage extends ConsumerStatefulWidget {
  const BrowserPage({super.key});

  @override
  ConsumerState<BrowserPage> createState() => BrowserPageState();
}

class BrowserPageState extends ConsumerState<BrowserPage> {
  final TextEditingController _urlController = TextEditingController();
  final Map<String, InAppWebViewController?> _controllers = {};
  String? _activeTabId;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(tabManagerProvider);
    final activeTab = ref.read(tabManagerProvider.notifier).activeTab;
    final isOnline = ref.watch(isOnlineProvider);

    if (_activeTabId == null && activeTab != null) {
      _activeTabId = activeTab.id;
    }

    if (activeTab != null) {
      _urlController.text = activeTab.url;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildWebLayout(context, tabs, activeTab, isOnline);
        }
        return _buildMobileLayout(context, tabs, activeTab, isOnline);
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    List<BrowserTab> tabs,
    BrowserTab? activeTab,
    bool isOnline,
  ) {
    return Column(
      children: [
        _buildAddressBar(activeTab, isOnline),
        if (!isOnline)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Container(
              width: double.infinity,
              color: Colors.orange.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Offline mode: showing cached pages if available',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        _buildTabsStrip(tabs, activeTab, isOnline),
        _buildLoadingBar(activeTab),

        Expanded(
          child: kIsWeb
              ? (activeTab == null
                    ? const Center(child: Text('No tabs'))
                    : WebBrowserView(tab: activeTab))
              : _buildInAppWebView(tabs),
        ),
        _buildBottomControls(activeTab, isOnline),
        const SummaryPanel(),
      ],
    );
  }

  Widget _buildWebLayout(
    BuildContext context,
    List<BrowserTab> tabs,
    BrowserTab? activeTab,
    bool isOnline,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildAddressBar(activeTab, isOnline),
              _buildTabsStrip(tabs, activeTab, isOnline),
              _buildLoadingBar(activeTab),
              Expanded(
                child: kIsWeb
                    ? (activeTab == null
                          ? const Center(child: Text('No tabs'))
                          : WebBrowserView(tab: activeTab))
                    : _buildInAppWebView(tabs),
              ),
              _buildBottomControls(activeTab, isOnline),
            ],
          ),
        ),
        const SizedBox(width: 400, child: SummaryPanel(isSidePanel: true)),
      ],
    );
  }

  Widget _buildLoadingBar(BrowserTab? activeTab) {
    final isLoading = activeTab?.isLoading ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isLoading ? 4 : 0,
      child: isLoading
          ? const LinearProgressIndicator(minHeight: 3)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildAddressBar(BrowserTab? tab, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'Enter URL...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (value) => _onGoPressed(value, isOnline),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => _onGoPressed(_urlController.text, isOnline),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsStrip(
    List<BrowserTab> tabs,
    BrowserTab? activeTab,
    bool isOnline,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  if (index == tabs.length) {
                    return _buildAddTabButton(isOnline);
                  }
                  final tab = tabs[index];
                  final isActive = tab.id == _activeTabId;
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(tabManagerProvider.notifier)
                          .setActiveTab(tab.id);
                      setState(() {
                        _activeTabId = tab.id;
                      });
                      _urlController.text = tab.url;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              tab.title ?? tab.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(tabManagerProvider.notifier)
                                  .closeTab(tab.id);
                              final newActive = ref
                                  .read(tabManagerProvider.notifier)
                                  .activeTab;
                              setState(() {
                                _activeTabId = newActive?.id;
                              });
                            },
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemCount: tabs.length + 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTabButton(bool isOnline) {
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        await ref
            .read(tabManagerProvider.notifier)
            .openNewTab('https://www.google.com');
        final newActive = ref.read(tabManagerProvider.notifier).activeTab;
        setState(() {
          _activeTabId = newActive?.id;
        });
      },
    );
  }

  Widget _buildInAppWebView(List<BrowserTab> tabs) {
    if (tabs.isEmpty) {
      return const Center(child: Text('No tabs'));
    }
    final index = tabs.indexWhere((t) => t.id == _activeTabId);
    final safeIndex = index == -1 ? 0 : index;
    final isOnline = ref.watch(isOnlineProvider);

    return IndexedStack(
      index: safeIndex,
      children: tabs.map((tab) {
        return InAppWebView(
          key: ValueKey(tab.id),
          initialUrlRequest: URLRequest(url: WebUri(tab.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowsInlineMediaPlayback: true,
            cacheEnabled: true,
          ),
          onWebViewCreated: (controller) async {
            _controllers[tab.id] = controller;

            // If offline, try to load from cache immediately
            if (!isOnline) {
              final cacheService = ref.read(pageCacheServiceProvider);
              final cache = cacheService.getPage(tab.url);
              if (cache != null) {
                await controller.loadData(
                  data: cache.html,
                  mimeType: 'text/html',
                  encoding: 'utf-8',
                  baseUrl: WebUri(tab.url),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loaded cached page (offline mode)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            }
          },
          onLoadStart: (controller, url) {
            final tab = ref.read(tabManagerProvider.notifier).activeTab;
            if (tab != null) {
              ref.read(tabManagerProvider.notifier).setLoading(tab.id, true);
            }
          },
          onLoadStop: (controller, url) async {
            final tab = ref.read(tabManagerProvider.notifier).activeTab;
            if (tab != null) {
              ref.read(tabManagerProvider.notifier).setLoading(tab.id, false);
              ref
                  .read(tabManagerProvider.notifier)
                  .updateUrl(tab.id, url?.toString() ?? tab.url);
              final title = await controller.getTitle();
              ref.read(tabManagerProvider.notifier).updateTitle(tab.id, title);

              // Only save to cache if online and successful load
              if (isOnline) {
                final html = await controller.getHtml();
                if (html != null && url != null) {
                  final cacheService = ref.read(pageCacheServiceProvider);
                  await cacheService.savePage(
                    url: url.toString(),
                    html: html,
                    title: title,
                  );
                }
              }
            }
          },
          onReceivedError: (controller, url, code) async {
            // If error occurs (e.g. offline during load), try cache
            final tab = ref.read(tabManagerProvider.notifier).activeTab;
            if (tab != null) {
              ref.read(tabManagerProvider.notifier).setLoading(tab.id, false);
              ref.read(tabManagerProvider.notifier).setError(tab.id, true);
            }

            // Only try loading cache if we haven't already loaded it manually
            // (to avoid double loading or loops)
            final cacheService = ref.read(pageCacheServiceProvider);
            final cache = cacheService.getPage(url.toString());

            if (cache != null) {
              await controller.loadData(
                data: cache.html,
                mimeType: 'text/html',
                encoding: 'utf-8',
                baseUrl: WebUri(url.toString()),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Loaded cached page (error recovery)'),
                  ),
                );
              }
            }
          },
          onDownloadStartRequest: (controller, request) async {
            final url = request.url.toString();
            final suggestedFilename = request.suggestedFilename;
            await _handleDownload(url, suggestedFilename);
          },
        );
      }).toList(),
    );
  }

  Future<void> _handleDownload(String url, String? suggestedFilename) async {
    try {
      final dio = Dio();

      final docsDir = await getApplicationDocumentsDirectory();
      String filename;
      if (suggestedFilename != null && suggestedFilename.trim().isNotEmpty) {
        filename = suggestedFilename;
      } else {
        final uri = Uri.parse(url);
        filename = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'download_${DateTime.now().millisecondsSinceEpoch}';
      }

      final savePath = p.join(docsDir.path, filename);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $filename...'),
          duration: const Duration(seconds: 2),
        ),
      );

      await dio.download(url, savePath);

      await ref
          .read(fileProvider.notifier)
          .addExistingFile(savePath, name: filename);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloaded: $filename')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Future<void> summarizeCurrentPage() async {
    final activeTab = ref.read(tabManagerProvider.notifier).activeTab;
    if (activeTab == null) return;
    final controller = _controllers[activeTab.id];
    if (controller == null) return;
    final html = await controller.getHtml() ?? '';
    if (html.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No content to summarize'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }
    await ref
        .read(summaryProvider.notifier)
        .summarizeWebPage(url: activeTab.url, html: html);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summary generated (check panel bottom)'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildBottomControls(BrowserTab? activeTab, bool isOnline) {
    final controller = activeTab == null ? null : _controllers[activeTab.id];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 56,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (controller != null && await controller.canGoBack()) {
                controller.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () async {
              if (controller != null && await controller.canGoForward()) {
                controller.goForward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isOnline
                ? () {
                    controller?.reload();
                  }
                : null,
          ),
          const Spacer(),
          FloatingActionButton.small(
            heroTag: 'summarizeFab',
            onPressed: kIsWeb
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'AI summary is only available on mobile/desktop for now.',
                        ),
                      ),
                    );
                  }
                : summarizeCurrentPage,
            child: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
    );
  }

  void _onGoPressed(String value, bool isOnline) async {
    if (value.trim().isEmpty) return;
    final activeTab = ref.read(tabManagerProvider.notifier).activeTab;
    if (activeTab == null) return;

    String url = value.trim();
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    final controller = _controllers[activeTab.id];
    if (isOnline) {
      final controller = _controllers[activeTab.id];

      await ref.read(tabManagerProvider.notifier).updateUrl(activeTab.id, url);
      controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      FocusScope.of(context).unfocus();
    } else {
      final cacheService = ref.read(pageCacheServiceProvider);
      final cache = cacheService.getPage(url);
      if (cache != null && controller != null) {
        await ref
            .read(tabManagerProvider.notifier)
            .updateUrl(activeTab.id, url);

        await controller.loadData(
          data: cache.html,
          mimeType: 'text/html',
          encoding: 'utf-8',
          baseUrl: WebUri(url),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loaded cached page (offline mode)')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline and no cached version available'),
            ),
          );
        }
      }
    }
    FocusScope.of(context).unfocus();
  }
}
