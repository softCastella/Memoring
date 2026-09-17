import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../catalog/background_pack.dart';
import '../../catalog/catalog_store.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import 'my_backgrounds_screen.dart';
import 'pack_detail_screen.dart';

class BackgroundStoreScreen extends StatefulWidget {
  const BackgroundStoreScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<BackgroundStoreScreen> createState() => _BackgroundStoreScreenState();
}

class _BackgroundStoreScreenState extends State<BackgroundStoreScreen> {
  String? _category;

  AppController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('배경 스토어'),
        actions: [
          IconButton(
            tooltip: '내 배경',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      MyBackgroundsScreen(controller: controller),
                ),
              );
            },
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final packs = controller.storePacksFor(_category);
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: [
              Text('배경 스토어', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '일상을 더 특별하게, 분위기 있는 배경으로 나만의 체크리스트를 꾸며보세요.',
                style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryChip(
                      label: '전체',
                      selected: _category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    for (final category in CatalogStore.categories) ...[
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: category,
                        selected: _category == category,
                        onTap: () => setState(() => _category = category),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (packs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    '공개된 배경팩이 아직 없어요. 관리자에서 팩을 공개하면 여기에 나타나요.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (final pack in packs) ...[
                  _PackCard(
                    pack: pack,
                    onTap: () => _openPack(pack),
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPack(BackgroundPack pack) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PackDetailScreen(
          controller: controller,
          packId: pack.id,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? palette.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? palette.accent : palette.divider,
            ),
          ),
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: selected ? palette.onAccent : palette.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack, required this.onTap});

  final BackgroundPack pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    final cover = coverBytesFor(pack);

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 168,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cover == null)
                    ColoredBox(color: palette.highlight)
                  else
                    Image.memory(cover, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x66000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack.name,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '배경 ${pack.imageCount}종',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!pack.isFree)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: palette.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '유료',
                          style: textTheme.labelMedium?.copyWith(
                            color: palette.onAccent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Uint8List? coverBytesFor(BackgroundPack pack) {
  if (pack.images.isEmpty) {
    return null;
  }
  final images = [...pack.images]
    ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  try {
    return Uint8List.fromList(base64Decode(images.first.base64Data));
  } catch (_) {
    return null;
  }
}
