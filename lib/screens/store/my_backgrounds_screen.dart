import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../catalog/background_pack.dart';
import '../../data/background_file_store.dart';
import '../../preview/sample_data.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/circular_check.dart';
import 'pack_detail_screen.dart';

class MyBackgroundsScreen extends StatelessWidget {
  const MyBackgroundsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('내 배경'),
          bottom: TabBar(
            labelColor: ThemeScope.of(context).palette.accent,
            unselectedLabelColor: ThemeScope.of(context).palette.textMuted,
            indicatorColor: ThemeScope.of(context).palette.accent,
            tabs: const [
              Tab(text: '적용한 배경'),
              Tab(text: '구매한 팩'),
              Tab(text: '즐겨찾기'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return TabBarView(
              children: [
                _AppliedTab(controller: controller),
                _PackListTab(
                  controller: controller,
                  packs: controller.storePacks
                      .where(
                        (pack) => controller.library.isDownloaded(pack.id),
                      )
                      .toList(),
                  emptyText:
                      '구매한 유료 팩은 서버 확인 후 여기에 표시돼요. 지금은 다운로드한 무료 팩만 보여요.',
                ),
                _PackListTab(
                  controller: controller,
                  packs: controller.storePacks
                      .where((pack) => controller.library.isFavorite(pack.id))
                      .toList(),
                  emptyText: '즐겨찾기한 배경팩이 없어요.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppliedTab extends StatelessWidget {
  const _AppliedTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    final packId = controller.library.appliedPackId;
    final assetId = controller.library.appliedAssetId;
    final pack = packId == null ? null : controller.catalog.packById(packId);
    BackgroundAsset? asset;
    if (pack != null && assetId != null) {
      for (final item in pack.images) {
        if (item.id == assetId) {
          asset = item;
          break;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      children: [
        if (pack == null || asset == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Text(
              controller.appearance.hasPersonalBackground
                  ? '갤러리에서 가져온 배경이 적용되어 있어요.'
                  : '적용한 스토어 배경이 없어요. 기본 디자인을 사용 중이에요.',
              style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          Text(pack.name, style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '배경 ${pack.imageCount}종',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          _AssetGrid(
            pack: pack,
            selectedId: asset.id,
            onTap: (item) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => PackDetailScreen(
                    controller: controller,
                    packId: pack.id,
                  ),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 22),
        Text('미리보기', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        _ChecklistPreview(controller: controller),
        const SizedBox(height: 18),
        if (pack != null && asset != null)
          FilledButton(
            onPressed: () async {
              await controller.applyCatalogBackground(pack: pack, asset: asset!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('배경을 적용했어요.')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('배경 적용하기'),
          ),
      ],
    );
  }
}

class _PackListTab extends StatelessWidget {
  const _PackListTab({
    required this.controller,
    required this.packs,
    required this.emptyText,
  });

  final AppController controller;
  final List<BackgroundPack> packs;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    if (packs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      itemCount: packs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pack = packs[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(pack.name, style: textTheme.titleMedium),
          subtitle: Text(
            '${pack.category} · 배경 ${pack.imageCount}종',
            style: textTheme.bodySmall,
          ),
          trailing: Icon(Icons.chevron_right, color: palette.textMuted),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => PackDetailScreen(
                  controller: controller,
                  packId: pack.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AssetGrid extends StatelessWidget {
  const _AssetGrid({
    required this.pack,
    required this.selectedId,
    required this.onTap,
  });

  final BackgroundPack pack;
  final String selectedId;
  final ValueChanged<BackgroundAsset> onTap;

  @override
  Widget build(BuildContext context) {
    final images = [...pack.images]
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final image in images)
          GestureDetector(
            onTap: () => onTap(image),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _bytes(image) == null
                      ? ColoredBox(
                          color: ThemeScope.of(context).palette.highlight,
                        )
                      : Image.memory(_bytes(image)!, fit: BoxFit.cover),
                  if (image.id == selectedId)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.check_circle,
                          color: ThemeScope.of(context).palette.accent,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Uint8List? _bytes(BackgroundAsset image) {
    try {
      return Uint8List.fromList(base64Decode(image.base64Data));
    } catch (_) {
      return null;
    }
  }
}

class _ChecklistPreview extends StatelessWidget {
  const _ChecklistPreview({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    final path = controller.appearance.personalBackgroundPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (path != null &&
                BackgroundFileStore.current?.readSync(path) != null)
              Image.memory(
                BackgroundFileStore.current!.readSync(path)!,
                fit: BoxFit.cover,
              )
            else
              ColoredBox(color: palette.highlight),
            ColoredBox(color: palette.background.withValues(alpha: 0.22)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Material(
                color: palette.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('오늘의 체크리스트', style: textTheme.titleSmall),
                      const SizedBox(height: 8),
                      for (var i = 0; i < PreviewSample.itemTitles.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircularCheck(checked: i == 0, onTap: () {}),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  PreviewSample.itemTitles[i],
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
