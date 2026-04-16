import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkunbound_core/linkunbound_core.dart';
import 'package:logging/logging.dart';

import '../../l10n/app_localizations.dart';
import '../../providers.dart';

final _log = Logger('PickerView');

class PickerView extends ConsumerStatefulWidget {
  const PickerView({required this.url, super.key});

  final String url;

  @override
  ConsumerState<PickerView> createState() => _PickerViewState();
}

class _PickerViewState extends ConsumerState<PickerView> {
  bool _alwaysOpen = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final browsers = ref.watch(browsersProvider);
    final iconsDir = ref.read(iconsDirProvider);
    final uri = Uri.tryParse(widget.url);
    final domain = uri?.host ?? widget.url;

    _log.info('Building: ${browsers.length} browsers, domain=$domain');

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          ref.read(appStateProvider.notifier).hide();
          return KeyEventResult.handled;
        }

        if (event is KeyDownEvent) {
          final index = _keyToIndex(event.logicalKey);
          if (index != null && index < browsers.length) {
            _launch(browsers[index], iconsDir);
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: Column(
        children: [
          _UrlHeader(url: widget.url, domain: domain),
          Divider(height: 0.5, color: colors.outline.withAlpha(50)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: browsers.length,
              itemBuilder: (context, index) => _BrowserRow(
                browser: browsers[index],
                iconPath: '${iconsDir.path}\\${browsers[index].id}.png',
                shortcut: index < 9 ? '${index + 1}' : null,
                onTap: () => _launch(browsers[index], iconsDir),
              ),
            ),
          ),
          Divider(height: 0.5, color: colors.outline.withAlpha(50)),
          _AlwaysOpenFooter(
            value: _alwaysOpen,
            onChanged: (v) => setState(() => _alwaysOpen = v),
          ),
        ],
      ),
    );
  }

  void _launch(Browser browser, Directory iconsDir) {
    final launchService = ref.read(launchServiceProvider);
    launchService.launch(browser.executablePath, widget.url, browser.extraArgs);

    if (_alwaysOpen) {
      final ruleService = ref.read(ruleServiceProvider);
      final uri = Uri.tryParse(widget.url);
      if (uri != null && uri.host.isNotEmpty) {
        ruleService.addRule(Rule(domain: uri.host, browserId: browser.id));
        ruleService.save();
        ref.invalidate(rulesProvider);
      }
    }

    ref.read(appStateProvider.notifier).hide();
  }

  int? _keyToIndex(LogicalKeyboardKey key) => switch (key) {
    LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 => 0,
    LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 => 1,
    LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3 => 2,
    LogicalKeyboardKey.digit4 || LogicalKeyboardKey.numpad4 => 3,
    LogicalKeyboardKey.digit5 || LogicalKeyboardKey.numpad5 => 4,
    LogicalKeyboardKey.digit6 || LogicalKeyboardKey.numpad6 => 5,
    LogicalKeyboardKey.digit7 || LogicalKeyboardKey.numpad7 => 6,
    LogicalKeyboardKey.digit8 || LogicalKeyboardKey.numpad8 => 7,
    LogicalKeyboardKey.digit9 || LogicalKeyboardKey.numpad9 => 8,
    _ => null,
  };
}

class _UrlHeader extends StatelessWidget {
  const _UrlHeader({required this.url, required this.domain});
  final String url;
  final String domain;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
      child: Row(
        children: [
          Icon(Icons.link, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  domain,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  url,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: url)),
            icon: Icon(Icons.copy, size: 14, color: colors.onSurfaceVariant),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: AppLocalizations.of(context)!.copyUrl,
          ),
        ],
      ),
    );
  }
}

class _BrowserRow extends StatefulWidget {
  const _BrowserRow({
    required this.browser,
    required this.iconPath,
    required this.onTap,
    this.shortcut,
  });

  final Browser browser;
  final String iconPath;
  final VoidCallback onTap;
  final String? shortcut;

  @override
  State<_BrowserRow> createState() => _BrowserRowState();
}

class _BrowserRowState extends State<_BrowserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconFile = File(widget.iconPath);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: _hovered ? colors.surfaceBright : Colors.transparent,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: iconFile.existsSync()
                    ? Image.file(iconFile, filterQuality: FilterQuality.medium)
                    : Icon(
                        Icons.public,
                        size: 28,
                        color: colors.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.browser.name,
                  style: TextStyle(fontSize: 13, color: colors.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.shortcut != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceBright,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.shortcut!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlwaysOpenFooter extends StatelessWidget {
  const _AlwaysOpenFooter({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: colors.primary,
              side: BorderSide(color: colors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.alwaysOpenHere,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
