import 'package:flutter/material.dart';
import '../../domain/entities/browser_tab.dart';

class WebBrowserView extends StatelessWidget {
  final BrowserTab tab;
  const WebBrowserView({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Web browser view is only used on Flutter Web builds.'),
    );
  }
}
