import 'package:flutter/material.dart';

class RuleRow extends StatelessWidget {
  const RuleRow({
    required this.domain,
    required this.browserName,
    required this.browsers,
    required this.onBrowserChanged,
    required this.onDelete,
    super.key,
  });

  final String domain;
  final String browserName;
  final List<({String id, String name})> browsers;
  final void Function(String browserId) onBrowserChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              domain,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: browsers.any((b) => b.name == browserName)
                    ? browsers.firstWhere((b) => b.name == browserName).id
                    : null,
                isExpanded: true,
                isDense: true,
                dropdownColor: colors.surfaceBright,
                style: Theme.of(context).textTheme.bodyMedium,
                items: browsers
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id != null) onBrowserChanged(id);
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.close, size: 16, color: colors.error),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            splashRadius: 16,
            tooltip: 'Delete rule',
          ),
        ],
      ),
    );
  }
}
