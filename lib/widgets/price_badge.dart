import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PriceBadge extends StatelessWidget {
  const PriceBadge({
    super.key,
    required this.isFree,
    this.compact = false,
  });

  final bool isFree;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: isFree ? const Color(0xCC5A463E) : palette.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isFree ? '무료' : '유료',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontSize: compact ? 10 : null,
        ),
      ),
    );
  }
}
