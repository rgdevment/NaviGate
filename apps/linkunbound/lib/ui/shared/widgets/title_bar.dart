import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../l10n/app_localizations.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({
    required this.tabController,
    required this.tabs,
    required this.onClose,
    this.onExit,
    super.key,
  });

  final TabController tabController;
  final List<String> tabs;
  final VoidCallback onClose;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isMac = Platform.isMacOS;
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        color: colors.surface,
        child: Row(
          children: [
            // macOS traffic lights are hidden via WindowChannel; reserve a
            // small left padding to align the title with the rest of the UI.
            const SizedBox(width: 12),
            Image.asset(
              'assets/app_icon.png',
              width: 16,
              height: 16,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(width: 8),
            Text(
              'LinkUnbound',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: TabBar(
                controller: tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: colors.onSurface,
                unselectedLabelColor: colors.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorColor: colors.primary,
                indicatorWeight: 2,
                dividerHeight: 0,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                tabs: tabs.map((t) => Tab(height: 32, text: t)).toList(),
              ),
            ),
            // On macOS the red traffic-light button hides the window;
            // expose an explicit "Exit" button so the user can fully quit
            // (matches the tray menu, since the dock icon is suppressed).
            if (!isMac) _CloseButton(onClose: onClose),
            if (isMac) ...[
              if (onExit != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: onExit,
                    icon: const Icon(Icons.power_settings_new, size: 14),
                    label: Text(l10n?.exit ?? 'Exit'),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          width: 46,
          height: 40,
          color: _hovered ? const Color(0xFFE81123) : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(
            Icons.close,
            size: 16,
            color: _hovered
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
