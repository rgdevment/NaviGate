import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
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
                      ? 'LinkUnbound is set as the default browser'
                      : 'LinkUnbound is not the default browser',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (isDefaultAsync.valueOrNull != true)
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'ms-settings:defaultapps?registeredAppUser=LinkUnbound',
                    ),
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Found ${ref.read(browsersProvider).length} browsers',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        width: 250,
                      ),
                    );
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
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: browsers.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              ref.read(browsersProvider.notifier).reorder(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Material(
                  color: colors.surfaceBright,
                  borderRadius: BorderRadius.circular(6),
                  elevation: 4,
                  child: child,
                ),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final b = browsers[index];
              return BrowserTile(
                key: ValueKey(b.id),
                name: b.name,
                iconPath: '${iconsDir.path}\\${b.id}.png',
                onTap: () => _showEditBrowserDialog(context, ref, b),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (action) async {
                        switch (action) {
                          case 'edit':
                            _showEditBrowserDialog(context, ref, b);
                          case 'duplicate':
                            await _duplicateBrowser(context, ref, b);
                          case 'remove':
                            ref.read(browsersProvider.notifier).remove(b.id);
                        }
                      },
                      icon: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Duplicate'),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove'),
                        ),
                      ],
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddBrowserDialog(BuildContext context, WidgetRef ref) {
    _showBrowserFormDialog(context, ref);
  }

  void _showEditBrowserDialog(
    BuildContext context,
    WidgetRef ref,
    Browser browser,
  ) {
    _showBrowserFormDialog(context, ref, existing: browser);
  }

  Future<void> _duplicateBrowser(
    BuildContext context,
    WidgetRef ref,
    Browser source,
  ) async {
    final copyId =
        'custom-${source.id}-copy-${DateTime.now().millisecondsSinceEpoch}';
    final copy = Browser(
      id: copyId,
      name: '${source.name} (Copy)',
      executablePath: source.executablePath,
      iconPath: source.iconPath,
      extraArgs: [...source.extraArgs],
      isCustom: true,
    );
    await ref.read(browsersProvider.notifier).add(copy);

    final iconsDir = ref.read(iconsDirProvider);
    final sourceIcon = File('${iconsDir.path}\\${source.id}.png');
    final destIcon = File('${iconsDir.path}\\$copyId.png');
    if (sourceIcon.existsSync()) {
      await sourceIcon.copy(destIcon.path);
    }
  }

  void _showBrowserFormDialog(
    BuildContext context,
    WidgetRef ref, {
    Browser? existing,
  }) {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final pathController =
        TextEditingController(text: existing?.executablePath ?? '');
    final argsController =
        TextEditingController(text: existing?.extraArgs.join(' ') ?? '');
    final iconController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;

        return Dialog(
          backgroundColor: colors.surfaceContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit browser' : 'Add custom browser',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _FormField(controller: nameController, label: 'Name'),
                  const SizedBox(height: 12),
                  _FormField(
                    controller: pathController,
                    label: 'Executable path',
                    enabled: isEdit ? existing.isCustom : true,
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    controller: argsController,
                    label: 'Extra arguments (space-separated)',
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    controller: iconController,
                    label: 'Custom icon path (optional)',
                    hint: 'Leave empty to auto-detect from exe',
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

                          final args = argsController.text.trim();
                          final extraArgs = args.isEmpty
                              ? <String>[]
                              : args.split(RegExp(r'\s+'));

                          final customIcon = iconController.text.trim();

                          if (isEdit) {
                            final updated = existing.copyWith(
                              name: name,
                              executablePath:
                                  existing.isCustom ? path : null,
                              extraArgs: extraArgs,
                            );
                            await ref
                                .read(browsersProvider.notifier)
                                .update(existing.id, updated);
                          } else {
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
                                    extraArgs: extraArgs,
                                  ),
                                );
                          }

                          final iconsDir = ref.read(iconsDirProvider);
                          final browserId = isEdit
                              ? existing.id
                              : 'custom-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-\$'), '')}';
                          final iconSource =
                              customIcon.isNotEmpty ? customIcon : path;
                          final iconDest =
                              File('${iconsDir.path}\\$browserId.png');

                          if (customIcon.isNotEmpty &&
                              iconDest.existsSync()) {
                            await iconDest.delete();
                          }

                          try {
                            await ref
                                .read(iconExtractorProvider)
                                .extractIcon(
                                  iconSource,
                                  '${iconsDir.path}\\$browserId.png',
                                );
                          } on Exception {
                            // Best-effort
                          }

                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: Text(isEdit ? 'Save' : 'Add'),
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

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
