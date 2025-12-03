import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../domain/entities/browser_tab.dart';

class WebBrowserView extends StatefulWidget {
  final BrowserTab tab;
  const WebBrowserView({super.key, required this.tab});

  @override
  State<WebBrowserView> createState() => _WebBrowserViewState();
}

class _WebBrowserViewState extends State<WebBrowserView> {
  late final String _viewType;
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();

    _viewType = 'web-browser-${widget.tab.id}';

    _iframe = html.IFrameElement()
      ..src = widget.tab.url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe!,
    );
  }

  @override
  void didUpdateWidget(covariant WebBrowserView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.url != oldWidget.tab.url) {
      // URL change from Flutter side (address bar / new tab)
      _iframe?.src = widget.tab.url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
