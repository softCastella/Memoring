import 'package:flutter/material.dart';

import '../models/date_key.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    final start = DateKey.weekStart(selected);

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _DayCell(
              date: DateKey.addDays(start, i),
              selected: DateKey.from(DateKey.addDays(start, i)) ==
                  DateKey.from(selected),
              palette: palette,
              textTheme: textTheme,
              onTap: onSelected,
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.palette,
    required this.textTheme,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final AppPalette palette;
  final TextTheme textTheme;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final numberStyle = textTheme.titleSmall?.copyWith(
      color: selected ? palette.onAccent : palette.text,
      fontWeight: FontWeight.w500,
    );
    final weekdayStyle = textTheme.labelMedium?.copyWith(
      color: selected ? palette.onAccent.withValues(alpha: 0.9) : palette.textMuted,
    );

    return GestureDetector(
      onTap: () => onTap(date),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? palette.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}', style: numberStyle),
                Text(DateKey.weekdaysShort[date.weekday - 1], style: weekdayStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
