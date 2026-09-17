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
              selected:
                  DateKey.from(DateKey.addDays(start, i)) ==
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
      color: palette.text,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      height: 1.0,
    );
    final weekdayStyle = textTheme.labelMedium?.copyWith(
      color: selected ? palette.text : palette.textMuted,
      height: 1.0,
    );

    return GestureDetector(
      onTap: () => onTap(date),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 28,
            child: Center(
              child: Text('${date.day}', style: numberStyle),
            ),
          ),
          Text(
            DateKey.weekdaysShort[date.weekday - 1],
            style: weekdayStyle,
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: selected ? palette.text : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
