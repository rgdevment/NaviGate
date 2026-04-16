import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../shared/widgets/base_dialog.dart';
import '../shared/widgets/group_card.dart';
import '../shared/widgets/section_header.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        SectionHeader(label: l10n.sectionAbout),
        GroupCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LinkUnbound',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Consumer(
                builder: (context, ref, _) {
                  final version =
                      ref.watch(packageInfoProvider).valueOrNull?.version ??
                      '…';
                  return Text(
                    l10n.appVersion(version),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.appDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.mitLicense,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(label: l10n.sectionSupport),
        GroupCard(
          child: _LinkRow(
            icon: Icons.coffee_outlined,
            label: l10n.donateLabel,
            description: l10n.donateDescription,
            color: const Color(0xFFFFDD00),
            url: 'https://buymeacoffee.com/rgdevment',
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(label: l10n.sectionOtherTools),
        GroupCard(
          child: _LinkRow(
            iconWidget: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/copypaste_icon.png',
                width: 20,
                height: 20,
              ),
            ),
            label: l10n.otherToolCopyPaste,
            description: l10n.otherToolCopyPasteDescription,
            color: colors.primary,
            url: 'https://github.com/rgdevment/CopyPaste',
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(label: l10n.sectionActions),
        GroupCard(
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.refresh,
                label: l10n.resetConfigLabel,
                description: l10n.resetConfigDescription,
                color: colors.error,
                onTap: () => _confirmReset(context, ref),
              ),
              Divider(height: 1, color: colors.outline.withAlpha(40)),
              _ActionRow(
                icon: Icons.delete_outline,
                label: l10n.unregisterLabel,
                description: l10n.unregisterDescription,
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
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => BaseDialog(
        title: l10n.resetConfigTitle,
        content: l10n.resetConfigContent,
        confirmLabel: l10n.reset,
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
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => BaseDialog(
        title: l10n.unregisterTitle,
        content: l10n.unregisterContent,
        confirmLabel: l10n.unregisterAction,
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

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.description,
    required this.color,
    required this.url,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final String description;
  final Color color;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (iconWidget != null)
              iconWidget!
            else
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
            Icon(Icons.open_in_new, size: 16, color: color.withAlpha(120)),
          ],
        ),
      ),
    );
  }
}
