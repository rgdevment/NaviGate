import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navigate_core/navigate_core.dart';

import '../../providers.dart';
import '../shared/widgets/base_dialog.dart';
import '../shared/widgets/group_card.dart';
import '../shared/widgets/rule_row.dart';
import '../shared/widgets/section_header.dart';

class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider);
    final browsers = ref.watch(browsersProvider);

    final browserList = browsers
        .map((b) => (id: b.id, name: b.name))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        const SectionHeader(label: 'URL RULES'),
        if (rules.isEmpty)
          GroupCard(
            child: Text(
              'No rules yet. Rules are created from the browser picker '
              'when you check "Always open here".',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          GroupCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Domain',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Browser',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                ...rules.map(
                  (rule) => RuleRow(
                    domain: rule.domain,
                    browserName: _browserName(rule.browserId, browsers),
                    browsers: browserList,
                    onBrowserChanged: (browserId) {
                      ref.read(rulesProvider.notifier).updateRule(
                            rule.domain,
                            browserId: browserId,
                          );
                    },
                    onDelete: () => _confirmDelete(
                      context,
                      ref,
                      rule.domain,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _browserName(String browserId, List<Browser> browsers) {
    for (final b in browsers) {
      if (b.id == browserId) return b.name;
    }
    return browserId;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String domain) {
    showDialog<void>(
      context: context,
      builder: (ctx) => BaseDialog(
        title: 'Delete rule',
        content: 'Remove the rule for "$domain"?',
        confirmLabel: 'Delete',
        confirmColor: Theme.of(ctx).colorScheme.error,
        onConfirm: () {
          ref.read(rulesProvider.notifier).removeRule(domain);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}
