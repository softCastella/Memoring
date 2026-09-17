import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../models/app_theme_id.dart';
import '../models/appearance_settings.dart';
import '../preview/sample_data.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/circular_check.dart';
import '../widgets/themed_background.dart';

class DecorateScreen extends StatefulWidget {
  const DecorateScreen({
    super.key,
    required this.controller,
    this.onOpenStore,
  });

  final AppController controller;
  final VoidCallback? onOpenStore;

  @override
  State<DecorateScreen> createState() => _DecorateScreenState();
}

class _DecorateScreenState extends State<DecorateScreen> {
  late AppearanceSettings _draft;
  bool _dirty = false;

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _draft = controller.appearance;
    controller.addListener(_onController);
  }

  @override
  void dispose() {
    controller.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (!_dirty) {
      setState(() => _draft = controller.appearance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(_draft.themeId);
    final live = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + inset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Text('꾸미기', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '색은 바로 바뀌고, 사진 배경은 미리본 뒤 적용할 수 있어요.',
          style: textTheme.bodyMedium?.copyWith(color: live.textMuted),
        ),
        const SizedBox(height: 18),
        _PreviewCard(draft: _draft),
        const SizedBox(height: 22),
        Text('색상 테마', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final theme in AppThemeId.values)
              _ThemeChip(
                id: theme,
                selected: controller.appearance.themeId == theme,
                onTap: () async {
                  await controller.setTheme(theme);
                  setState(() {
                    _draft = _draft.copyWith(themeId: theme);
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 22),
        Text('배경', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        if (widget.onOpenStore != null) ...[
          OutlinedButton(
            onPressed: widget.onOpenStore,
            style: OutlinedButton.styleFrom(
              foregroundColor: live.text,
              side: BorderSide(color: live.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('배경 스토어'),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _pickImage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: live.text,
                  side: BorderSide(color: live.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('갤러리에서 선택'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _draft.hasPersonalBackground ? _clearImage : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: live.text,
                  side: BorderSide(color: live.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('사진 제거'),
              ),
            ),
          ],
        ),
        if (_draft.hasPersonalBackground) ...[
          const SizedBox(height: 18),
          _SliderRow(
            label: '가로 위치',
            value: _draft.offsetX,
            min: -1,
            max: 1,
            onChanged: (value) => _updateDraft(_draft.copyWith(offsetX: value)),
          ),
          _SliderRow(
            label: '세로 위치',
            value: _draft.offsetY,
            min: -1,
            max: 1,
            onChanged: (value) => _updateDraft(_draft.copyWith(offsetY: value)),
          ),
          _SliderRow(
            label: '확대',
            value: _draft.scale,
            min: 1,
            max: 2.4,
            onChanged: (value) => _updateDraft(_draft.copyWith(scale: value)),
          ),
          _SliderRow(
            label: '흐림',
            value: _draft.blur,
            min: 0,
            max: 16,
            onChanged: (value) => _updateDraft(_draft.copyWith(blur: value)),
          ),
          _SliderRow(
            label: '카드 투명도',
            value: _draft.cardOpacity,
            min: 0.62,
            max: 1,
            onChanged: (value) =>
                _updateDraft(_draft.copyWith(cardOpacity: value)),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _dirty ? _apply : null,
          style: FilledButton.styleFrom(
            backgroundColor: live.accent,
            foregroundColor: live.onAccent,
            disabledBackgroundColor: live.divider,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('미리보기 적용'),
        ),
        TextButton(
          onPressed: () async {
            await controller.restoreDefaultAppearance();
            setState(() {
              _draft = controller.appearance;
              _dirty = false;
            });
          },
          child: Text(
            '기본 디자인으로 복원',
            style: textTheme.labelLarge?.copyWith(color: palette.accent),
          ),
        ),
        ],
      ),
    );
  }

  void _updateDraft(AppearanceSettings next) {
    setState(() {
      _draft = next;
      _dirty = true;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null) {
      return;
    }
    final path = await controller.persistPickedBackground(
      await picked.readAsBytes(),
      ext: p.extension(picked.name),
    );
    _updateDraft(
      _draft.copyWith(
        personalBackgroundPath: path,
        cardOpacity: _draft.cardOpacity < 0.88 ? _draft.cardOpacity : 0.88,
      ),
    );
  }

  void _clearImage() {
    _updateDraft(
      _draft.copyWith(
        clearPersonalBackground: true,
        scale: 1,
        offsetX: 0,
        offsetY: 0,
        blur: 0,
        cardOpacity: 1,
      ),
    );
  }

  Future<void> _apply() async {
    await controller.applyAppearance(_draft);
    setState(() {
      _draft = controller.appearance;
      _dirty = false;
    });
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final AppThemeId id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(id);
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? palette.accent : palette.divider,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(id.label, style: textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelLarge),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.draft});

  final AppearanceSettings draft;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(draft.themeId);
    final textTheme = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 210,
        child: ThemeScope(
          palette: palette,
          appearance: draft,
          child: ThemedBackground(
            palette: palette,
            appearance: draft,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '미리보기',
                    style: textTheme.labelLarge?.copyWith(color: palette.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < PreviewSample.itemTitles.length; i++) ...[
                          AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                CircularCheck(checked: i == 0, onTap: () {}),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    PreviewSample.itemTitles[i],
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: i == 0
                                          ? palette.completedText
                                          : palette.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
