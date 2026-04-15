import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../providers.dart';
import '../shared/widgets/title_bar.dart';
import 'about_page.dart';
import 'general_page.dart';
import 'rules_page.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TitleBar(
          tabController: _tabController,
          tabs: const ['General', 'Rules', 'About'],
          onClose: () async {
            await windowManager.hide();
            ref.read(appStateProvider.notifier).hide();
          },
        ),
        Divider(
          height: 0.5,
          color: Theme.of(context).colorScheme.outline.withAlpha(60),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              GeneralPage(),
              RulesPage(),
              AboutPage(),
            ],
          ),
        ),
      ],
    );
  }
}
