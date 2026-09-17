import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

class SoftBottomBar extends StatelessWidget {
  const SoftBottomBar({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Material(
      color: ThemeScope.of(context).cardColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _Item(
                icon: Icons.home_rounded,
                label: '오늘',
                selected: index == 0,
                onTap: () => onChanged(0),
                palette: palette,
              ),
              _Item(
                icon: Icons.view_list_outlined,
                label: '기록',
                selected: index == 1,
                onTap: () => onChanged(1),
                palette: palette,
              ),
              _Item(
                icon: Icons.settings_outlined,
                label: '설정',
                selected: index == 2,
                onTap: () => onChanged(2),
                palette: palette,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final color = selected ? palette.accent : palette.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
