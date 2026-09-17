import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CircularCheck extends StatelessWidget {
  const CircularCheck({
    super.key,
    required this.checked,
    required this.onTap,
  });

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Semantics(
      button: true,
      checked: checked,
      label: checked ? '완료 취소' : '완료',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? palette.accent : Colors.transparent,
            border: Border.all(
              color: checked ? palette.accent : palette.checkBorder,
              width: 1.6,
            ),
          ),
          child: checked
              ? Icon(Icons.check, size: 14, color: palette.onAccent)
              : null,
        ),
      ),
    );
  }
}
