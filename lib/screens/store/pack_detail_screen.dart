import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../catalog/background_pack.dart';
import '../../catalog/entitlement.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';

class PackDetailScreen extends StatelessWidget {
  const PackDetailScreen({
    super.key,
    required this.controller,
    required this.packId,
  });

  final AppController controller;
  final String packId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pack = controller.catalog.packById(packId);
        final palette = ThemeScope.of(context).palette;
        final textTheme = Theme.of(context).textTheme;
        if (pack == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(),
            body: const Center(child: Text('팩을 찾을 수 없어요.')),
          );
        }

        final images = [...pack.images]
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(pack.name),
            actions: [
              IconButton(
                tooltip: controller.library.isFavorite(pack.id) ? '즐겨찾기 해제' : '즐겨찾기',
                onPressed: () => controller.togglePackFavorite(pack.id),
                icon: Icon(
                  controller.library.isFavorite(pack.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: palette.accent,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: [
              Text(pack.name, style: textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                '${pack.category} · 배경 ${pack.imageCount}종 · ${pack.isFree ? '무료' : '유료'}',
                style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
              ),
              if (pack.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(pack.description, style: textTheme.bodyMedium),
              ],
              const SizedBox(height: 18),
              if (images.isEmpty)
                Text(
                  '아직 등록된 이미지가 없어요.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: [
                    for (final image in images)
                      _AssetTile(
                        pack: pack,
                        asset: image,
                        selected: controller.library.isApplied(
                          packId: pack.id,
                          assetId: image.id,
                        ),
                        onTap: () => _onAssetTap(context, pack, image),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              if (!pack.isFree)
                Material(
                  color: palette.highlight,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      '유료 배경은 클라이언트 구매 표시만으로 열리지 않아요. 스토어 결제와 서버 확인이 연결되면 사용할 수 있습니다.',
                      style: textTheme.bodySmall,
                    ),
                  ),
                )
              else
                FilledButton(
                  onPressed: images.isEmpty
                      ? null
                      : () => _downloadOrApply(context, pack, images.first),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    controller.library.isDownloaded(pack.id)
                        ? '배경 적용하기'
                        : '다운로드 후 적용',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onAssetTap(
    BuildContext context,
    BackgroundPack pack,
    BackgroundAsset asset,
  ) async {
    if (!await controller.canAccessPack(pack)) {
      if (context.mounted) {
        _showLocked(context);
      }
      return;
    }
    if (context.mounted) {
      await _apply(context, pack, asset);
    }
  }

  Future<void> _downloadOrApply(
    BuildContext context,
    BackgroundPack pack,
    BackgroundAsset asset,
  ) async {
    if (!await controller.canAccessPack(pack)) {
      if (context.mounted) {
        _showLocked(context);
      }
      return;
    }
    try {
      await controller.downloadPack(pack);
      await controller.applyCatalogBackground(pack: pack, asset: asset);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('배경을 적용했어요.')));
      }
    } on PaidContentLocked {
      if (context.mounted) {
        _showLocked(context);
      }
    }
  }

  Future<void> _apply(
    BuildContext context,
    BackgroundPack pack,
    BackgroundAsset asset,
  ) async {
    try {
      await controller.downloadPack(pack);
      await controller.applyCatalogBackground(pack: pack, asset: asset);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('배경을 적용했어요.')));
      }
    } on PaidContentLocked {
      if (context.mounted) {
        _showLocked(context);
      }
    }
  }

  void _showLocked(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('유료 배경은 스토어 결제와 서버 확인 후에만 열 수 있어요.')),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.pack,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final BackgroundPack pack;
  final BackgroundAsset asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    Uint8List? bytes;
    try {
      bytes = Uint8List.fromList(base64Decode(asset.base64Data));
    } catch (_) {
      bytes = null;
    }

    return Material(
      color: palette.highlight,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes == null)
              Icon(Icons.image_outlined, color: palette.textMuted)
            else
              Image.memory(bytes, fit: BoxFit.cover),
            if (!pack.isFree)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.28),
                child: const Center(
                  child: Icon(Icons.lock_outline, color: Colors.white),
                ),
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
                    child: Icon(Icons.check, size: 14, color: palette.onAccent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
