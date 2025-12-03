import 'dart:io';
import 'package:browser_lite/features/summary/presentation/providers/summary_provider.dart';
import 'package:browser_lite/features/summary/presentation/widgets/summary_panel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:docx_to_text/docx_to_text.dart';
import '../providers/file_provider.dart';
import '../../domain/entities/downloaded_file.dart';
import 'package:flutter/foundation.dart';

class FilesPage extends ConsumerWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(fileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Pick file from device',
            onPressed: () => _pickFile(context, ref),
          ),
        ],
      ),
      body: files.isEmpty
          ? const Center(
              child: Text(
                'No files yet.\nPick from device to add.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              itemCount: files.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final file = files[index];
                return _FileTile(file: file);
              },
            ),
      bottomSheet: const SummaryPanel(),
    );
  }

  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'File picking & local storage is only supported on mobile/desktop for now.',
            ),
          ),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx', 'xlsx'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final filePath = result.files.single.path!;
    final name = result.files.single.name;

    await ref.read(fileProvider.notifier).addFileFromPath(filePath, name);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File added: $name')));
    }
  }
}

class _FileTile extends ConsumerWidget {
  final DownloadedFile file;

  const _FileTile({required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizeInKb = (file.sizeBytes / 1024).toStringAsFixed(1);
    final dateStr =
        '${file.createdAt.day}/${file.createdAt.month}/${file.createdAt.year}';

    return ListTile(
      leading: _buildIcon(),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${file.extension.toUpperCase()} • $sizeInKb KB • $dateStr',
      ),
      onTap: () async {
        final result = await OpenFilex.open(file.path);
        if (context.mounted && result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file (${result.message})')),
          );
        }
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Summarize',
            onPressed: () async {
              await _onSummarizePressed(context, ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Delete file?'),
                    content: Text(
                      'Do you really want to delete "${file.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await ref.read(fileProvider.notifier).removeFile(file.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    switch (file.extension.toLowerCase()) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description);
      case 'ppt':
      case 'pptx':
        return const Icon(Icons.slideshow);
      case 'xls':
      case 'xlsx':
        return const Icon(Icons.grid_on);
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }

  Future<void> _onSummarizePressed(BuildContext context, WidgetRef ref) async {
    final ext = file.extension.toLowerCase();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extracting text from ${file.name}...'),
          duration: Duration(seconds: 1),
        ),
      );

      String text;

      if (ext == 'pdf') {
        final doc = await PDFDoc.fromPath(file.path);
        text = await doc.text;
      } else if (ext == 'docx') {
        final f = File(file.path);
        final bytes = await f.readAsBytes();
        text = docxToText(bytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Summary not supported for .$ext files yet'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No readable text found in document'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      await ref
          .read(summaryProvider.notifier)
          .summarizePlainText(url: file.id, sourceType: 'file', html: text);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Summary generated. Scroll down to AI Summary panel below.',
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to extract text: $e')));
      }
    }
  }
}
