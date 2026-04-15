import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../providers.dart';
import 'picker_view.dart';

class PickerWindow extends ConsumerStatefulWidget {
  const PickerWindow({required this.url, super.key});

  final String url;

  @override
  ConsumerState<PickerWindow> createState() => _PickerWindowState();
}

class _PickerWindowState extends ConsumerState<PickerWindow>
    with SingleTickerProviderStateMixin, WindowListener {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _animController.dispose();
    super.dispose();
  }

  @override
  void onWindowBlur() {
    ref.read(appStateProvider.notifier).hide();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline.withAlpha(60)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PickerView(url: widget.url),
            ),
          ),
        ),
      ),
    );
  }
}
