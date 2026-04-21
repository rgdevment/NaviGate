import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';

import '../../providers.dart';
import 'picker_view.dart';

final _log = Logger('PickerWindow');

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
  bool _active = false;
  Timer? _activeTimer;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _activeTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _active = true);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _activeTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  void onWindowBlur() {
    if (!_active) return;
    _log.fine('Picker lost focus, hiding');
    ref.read(appStateProvider.notifier).hide();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          alignment: Alignment.topCenter,
          child: PickerView(url: widget.url),
        ),
      ),
    );
  }
}
