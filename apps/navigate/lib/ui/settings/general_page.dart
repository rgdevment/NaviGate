import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navigate_core/navigate_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../shared/widgets/browser_tile.dart';
import '../shared/widgets/group_card.dart';
import '../shared/widgets/section_header.dart';

class GeneralPage extends ConsumerWidget {
  const GeneralPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final browsers = ref.watch(browsersProvider);
    final isDefaultAsync = ref.watch(isDefaultBrowserProvider);
    final isStartupAsync = ref.watch(isStartupEnabledProvider);
    final iconsDir = ref.read(iconsDirProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        const SectionHeader(label: 'DEFAULT BROWSER'),
        GroupCard(
          child: Row(
            children: [
              Icon(
                isDefaultAsync.valueOrNull == true
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                size: 20,
                color: isDefaultAsync.valueOrNull == true
                    ? Colors.green
                    : colors.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isDefaultAsync.valueOrNull == true
                      ? 'NaviGate is set as the default browser'
                      : 'NaviGate is not the default browser',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (isDefaultAsync.valueOrNull != true)
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('ms-settings:defaultapps'),
                  ),
                  child: const Text('Set default'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(label: 'STARTUP'),
        GroupCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Launch at Windows startup',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Switch(
                value: isStartupAsync.valueOrNull ?? false,
                onChanged: (enabled) async {
                  final service = ref.read(startupServiceProvider);
                  if (enabled) {
                    await service.enable(Platform.resolvedExecutable);
                  } else {
                    await service.disable();
                  }
                  ref.invalidate(isStartupEnabledProvider);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(
          label: 'BROWSERS',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showAddBrowserDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Add custom browser',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () async {
                  await ref.read(browsersProvider.notifier).refresh();
                  final iconExtractor = ref.read(iconExtractorProvider);
                  for (final browser
                      in ref.read(browsersProvider)) {
                    try {
                      await iconExtractor.extractIcon(
                        browser.executablePath,
                        '${iconsDir.path}\\${browser.id}.png',
                      );
                    } on Exception {
                      // Best-effort icon extraction
                    }
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Refresh browsers',
              ),
            ],
          ),
        ),
        GroupCard(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            children: browsers
                .map(
                  (b) => BrowserTile(
                    name: b.name,
                    iconPath: '${iconsDir.path}\\${b.id}.png',
                    trailing: b.isCustom
                        ? IconButton(
                            onPressed: () => ref
                                .read(browsersProvider.notifier)
                                .remove(b.id),
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: colors.error,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            tooltip: 'Remove',
                          )
                        : null,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  void _showAddBrowserDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final pathController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;

        return Dialog(
          backgroundColor: colors.surfaceContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add custom browser',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      filled: true,
                      fillColor: colors.surfaceBright,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pathController,
                    decoration: InputDecoration(
                      labelText: 'Executable path',
                      filled: true,
                      fillColor: colors.surfaceBright,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final path = pathController.text.trim();
                          if (name.isEmpty || path.isEmpty) return;

                          final id = name
                              .toLowerCase()
                              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                              .replaceAll(RegExp(r'^-|-$'), '');

                          await ref.read(browsersProvider.notifier).add(
                                Browser(
                                  id: 'custom-$id',
                                  name: name,
                                  executablePath: path,
                                  iconPath: path,
                                  isCustom: true,
                                ),
                              );

                          final iconsDir = ref.read(iconsDirProvider);
                          try {
                            await ref.read(iconExtractorProvider).extractIcon(
                                  path,
                                  '${iconsDir.path}\\custom-$id.png',
                                );
                          } on Exception {
                            // Best-effort
                          }

                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
