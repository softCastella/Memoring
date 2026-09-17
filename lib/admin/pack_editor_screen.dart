import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../catalog/background_pack.dart';
import '../catalog/catalog_store.dart';
import '../theme/app_theme.dart';

class PackEditorScreen extends StatefulWidget {
  const PackEditorScreen({
    super.key,
    required this.catalog,
    required this.packId,
    required this.onBack,
  });

  final CatalogStore catalog;
  final String packId;
  final VoidCallback onBack;

  @override
  State<PackEditorScreen> createState() => _PackEditorScreenState();
}

class _PackEditorScreenState extends State<PackEditorScreen> {
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _productId;
  late String _category;
  late bool _isFree;
  late bool _isPublished;
  late List<BackgroundAsset> _images;
  String? _selectedImageId;
  bool _dirty = false;

  BackgroundPack? get _pack => widget.catalog.packById(widget.packId);

  @override
  void initState() {
    super.initState();
    final pack = _pack;
    _name = TextEditingController(text: pack?.name ?? '');
    _description = TextEditingController(text: pack?.description ?? '');
    _productId = TextEditingController(text: pack?.storeProductId ?? '');
    _category = pack?.category ?? '꽃';
    _isFree = pack?.isFree ?? true;
    _isPublished = pack?.isPublished ?? false;
    _images = [...?pack?.images];
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _productId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    if (_pack == null) {
      return Center(
        child: TextButton(
          onPressed: widget.onBack,
          child: const Text('팩 목록으로 돌아가기'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
      children: [
        Row(
          children: [
            Text('배경 관리', style: textTheme.headlineSmall),
            const Spacer(),
            FilledButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('이미지 등록'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.onAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '선택한 팩',
                    style: textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _name.text.trim().isEmpty ? '이름 없는 팩' : _name.text.trim(),
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('배경 ${_images.length}종', style: textTheme.bodySmall),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onBack,
              child: Text(
                '팩 목록으로 돌아가기',
                style: textTheme.labelLarge?.copyWith(color: palette.accent),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '더보기',
              onSelected: (value) {
                if (value == 'delete') {
                  _deletePack();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('이 팩 삭제'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width > 1100
                ? 4
                : width > 800
                ? 3
                : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.28,
              children: [
                for (final image in _sortedImages) _imageTile(image),
                _addTile(),
              ],
            );
          },
        ),
        if (_selectedImageId != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: _moveLeft, child: const Text('앞으로')),
              TextButton(onPressed: _moveRight, child: const Text('뒤로')),
              TextButton(
                onPressed: _deleteSelected,
                child: const Text('선택 이미지 삭제'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        _FieldRow(
          label: '팩 이름',
          child: TextField(
            controller: _name,
            onChanged: (_) => setState(() => _dirty = true),
          ),
        ),
        _FieldRow(
          label: '소개',
          child: TextField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => setState(() => _dirty = true),
          ),
        ),
        _FieldRow(
          label: '카테고리',
          child: Wrap(
            spacing: 8,
            children: [
              for (final category in CatalogStore.categories)
                ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  showCheckmark: false,
                  onSelected: (_) => setState(() {
                    _category = category;
                    _dirty = true;
                  }),
                ),
            ],
          ),
        ),
        _FieldRow(
          label: '판매구분',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SelectOption(
                    label: '무료',
                    selected: _isFree,
                    onTap: () => setState(() {
                      _isFree = true;
                      _dirty = true;
                    }),
                  ),
                  const SizedBox(width: 22),
                  _SelectOption(
                    label: '유료',
                    selected: !_isFree,
                    onTap: () => setState(() {
                      _isFree = false;
                      _dirty = true;
                    }),
                  ),
                ],
              ),
              if (!_isFree) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _productId,
                  onChanged: (_) => setState(() => _dirty = true),
                  decoration: const InputDecoration(
                    hintText: '스토어 상품 ID (금액이 아닙니다)',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '결제 금액은 앱스토어 상품 설정에서 바뀝니다. 여기에 숫자를 넣는다고 가격이 바뀌지 않습니다.',
                  style: textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        _FieldRow(
          label: '공개 상태',
          child: Row(
            children: [
              _SelectOption(
                label: '비공개',
                selected: !_isPublished,
                onTap: () => setState(() {
                  _isPublished = false;
                  _dirty = true;
                }),
              ),
              const SizedBox(width: 22),
              _SelectOption(
                label: '공개',
                selected: _isPublished,
                onTap: () => setState(() {
                  _isPublished = true;
                  _dirty = true;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: palette.highlight,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: palette.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '이 팩의 구매자에게 새 배경이 제공됩니다. 별도 팩은 따로 구매 대상입니다. 실제 구매 검증은 이후 서버 연동에서 처리합니다.',
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _dirty ? _save : null,
          style: FilledButton.styleFrom(
            backgroundColor: palette.accent,
            foregroundColor: palette.onAccent,
            disabledBackgroundColor: palette.divider,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('변경사항 저장'),
        ),
      ],
    );
  }

  List<BackgroundAsset> get _sortedImages {
    final list = [..._images];
    list.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return list;
  }

  Widget _imageTile(BackgroundAsset image) {
    final palette = ThemeScope.of(context).palette;
    final selected = _selectedImageId == image.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedImageId = image.id),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.accent : Colors.transparent,
            width: selected ? 2 : 0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                Uint8List.fromList(base64Decode(image.base64Data)),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(color: palette.highlight);
                },
              ),
              if (selected)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: palette.onAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addTile() {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _pickImages,
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _DashedRRectPainter(color: palette.divider, radius: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: palette.textMuted),
              const SizedBox(height: 8),
              Text('이미지 추가', style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 88);
    if (files.isEmpty) {
      return;
    }
    final payloads = <({Uint8List bytes, String name, String mimeType})>[];
    for (final file in files) {
      payloads.add((
        bytes: await file.readAsBytes(),
        name: file.name,
        mimeType: file.mimeType ?? 'image/jpeg',
      ));
    }
    final next = await widget.catalog.addImages(
      packId: widget.packId,
      files: payloads,
    );
    setState(() {
      _images = [...next.images];
    });
  }

  void _moveLeft() {
    _shiftSelected(-1);
  }

  void _moveRight() {
    _shiftSelected(1);
  }

  void _shiftSelected(int delta) {
    final list = _sortedImages;
    final index = list.indexWhere((item) => item.id == _selectedImageId);
    final nextIndex = index + delta;
    if (index < 0 || nextIndex < 0 || nextIndex >= list.length) {
      return;
    }
    final current = list[index];
    final swap = list[nextIndex];
    setState(() {
      _images = [
        for (final item in _images)
          if (item.id == current.id)
            item.copyWith(sortIndex: swap.sortIndex)
          else if (item.id == swap.id)
            item.copyWith(sortIndex: current.sortIndex)
          else
            item,
      ];
      _dirty = true;
    });
  }

  void _deleteSelected() {
    setState(() {
      _images = _images.where((item) => item.id != _selectedImageId).toList();
      _selectedImageId = null;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final pack = _pack;
    if (pack == null) {
      return;
    }
    await widget.catalog.upsertPack(
      pack.copyWith(
        name: _name.text.trim().isEmpty ? '새 배경팩' : _name.text.trim(),
        description: _description.text.trim(),
        category: _category,
        isFree: _isFree,
        isPublished: _isPublished,
        storeProductId: _isFree ? null : _productId.text.trim(),
        clearStoreProductId: _isFree,
        images: _images,
      ),
    );
    setState(() => _dirty = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPublished
                ? '저장했어요. 앱 배경 스토어에 바로 보여요.'
                : '저장했어요. 아직 비공개라 앱 스토어에는 안 보여요.',
          ),
        ),
      );
    }
  }

  Future<void> _deletePack() async {
    await widget.catalog.deletePack(widget.packId);
    widget.onBack();
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.labelLarge),
                const SizedBox(height: 8),
                child,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(label, style: textTheme.labelLarge),
                ),
              ),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}

class _SelectOption extends StatelessWidget {
  const _SelectOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? palette.accent : palette.checkBorder,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
