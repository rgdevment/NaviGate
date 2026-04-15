import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({
    required this.tabController,
    required this.tabs,
    required this.onClose,
    super.key,
  });

  final TabController tabController;
  final List<String> tabs;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        color: colors.surface,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              'NaviGate',
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
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 14),
                tabs: tabs.map((t) => Tab(height: 32, text: t)).toList(),
              ),
            ),
            _CloseButton(onClose: onClose),
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
