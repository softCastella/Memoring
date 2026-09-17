import 'package:flutter/material.dart';

import '../models/date_key.dart';
import '../theme/app_theme.dart';

class DateSelector extends StatelessWidget {
  const DateSelector({
    super.key,
    required this.date,
    required this.onChanged,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    final today = DateKey.today();
    final isToday = DateKey.from(date) == DateKey.from(today);

    return Row(
      children: [
        _ArrowButton(
          icon: Icons.chevron_left,
          onTap: () => onChanged(DateKey.addDays(date, -1)),
        ),
        Expanded(
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _pick(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      Text(
                        '${date.year}년',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.month}월 ${date.day}일 ${_weekday(date)}',
                        style: textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isToday)
                GestureDetector(
                  onTap: () => onChanged(today),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Text(
                      '오늘로',
                      style: textTheme.labelMedium?.copyWith(
                        color: palette.accent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right,
          onTap: () => onChanged(DateKey.addDays(date, 1)),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final palette = ThemeScope.of(context).palette;
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(date.year - 5),
      lastDate: DateTime(date.year + 5),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: palette.accent,
              onPrimary: palette.onAccent,
              surface: palette.surface,
              onSurface: palette.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  static String _weekday(DateTime date) {
    const names = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return names[date.weekday - 1];
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon),
    );
  }
}
