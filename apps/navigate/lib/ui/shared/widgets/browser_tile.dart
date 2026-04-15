import 'dart:io';

import 'package:flutter/material.dart';

class BrowserTile extends StatelessWidget {
  const BrowserTile({
    required this.name,
    required this.iconPath,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String name;
  final String iconPath;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconFile = File(iconPath);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: iconFile.existsSync()
                  ? Image.file(iconFile, filterQuality: FilterQuality.medium)
                  : Icon(Icons.public, size: 28, color: colors.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
