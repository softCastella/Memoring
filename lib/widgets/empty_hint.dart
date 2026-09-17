import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class EmptyHint extends StatelessWidget {
  const EmptyHint({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
      child: Column(
        children: [
          Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: textTheme.labelLarge?.copyWith(color: palette.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
