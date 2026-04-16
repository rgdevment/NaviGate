import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../shared/widgets/base_dialog.dart';
import '../shared/widgets/group_card.dart';
import '../shared/widgets/section_header.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        const SectionHeader(label: 'ABOUT'),
        GroupCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LinkUnbound',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Open-source browser picker for Windows.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text('MIT License', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(label: 'ACTIONS'),
        GroupCard(
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.refresh,
                label: 'Reset configuration',
                description: 'Clear all browsers and rules, then re-scan',
                color: colors.error,
                onTap: () => _confirmReset(context, ref),
              ),
              Divider(height: 1, color: colors.outline.withAlpha(40)),
              _ActionRow(
                icon: Icons.delete_outline,
                label: 'Unregister LinkUnbound',
                description: 'Remove from Windows browser list',
                color: colors.error,
                onTap: () => _confirmUnregister(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => BaseDialog(
        title: 'Reset configuration',
        content:
            'This will delete all browsers, rules and icons, then re-scan '
            'installed browsers. Continue?',
        confirmLabel: 'Reset',
        confirmColor: Theme.of(ctx).colorScheme.error,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          final browserService = ref.read(browserServiceProvider);
          await browserService.reset();
          await browserService.scanAndMerge();
          final iconsDir = ref.read(iconsDirProvider);
          final iconExtractor = ref.read(iconExtractorProvider);
          for (final browser in browserService.browsers) {
            try {
              await iconExtractor.extractIcon(
                browser.executablePath,
                '${iconsDir.path}\\${browser.id}.png',
              );
            } on Exception {
              // Best-effort
            }
          }
          ref.invalidate(browsersProvider);
          ref.invalidate(rulesProvider);
        },
      ),
    );
  }

  void _confirmUnregister(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => BaseDialog(
        title: 'Unregister LinkUnbound',
        content:
            'This will remove LinkUnbound from the Windows browser list. '
            'You may need to change your default browser in Windows Settings '
            'afterwards. Continue?',
        confirmLabel: 'Unregister',
        confirmColor: Theme.of(ctx).colorScheme.error,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await ref.read(registrationServiceProvider).unregister();
          ref.invalidate(isDefaultBrowserProvider);
        },
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: color),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: color.withAlpha(120)),
          ],
        ),
      ),
    );
  }
}
