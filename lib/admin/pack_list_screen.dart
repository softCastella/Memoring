import 'package:flutter/material.dart';

import '../catalog/catalog_store.dart';
import '../theme/app_theme.dart';

class PackListScreen extends StatelessWidget {
  const PackListScreen({
    super.key,
    required this.catalog,
    required this.onOpenPack,
  });

  final CatalogStore catalog;
  final ValueChanged<String> onOpenPack;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: catalog,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('배경 관리', style: textTheme.headlineSmall),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      final pack = await catalog.createPack();
                      onOpenPack(pack.id);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('새 팩'),
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.onAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '공개로 저장한 팩은 앱 배경 스토어에 보여요.',
                style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: catalog.packs.isEmpty
                    ? Center(
                        child: Text(
                          '아직 배경팩이 없습니다. 새 팩을 만들어 이미지를 등록해 보세요.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: catalog.packs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final pack = catalog.packs[index];
                          return Material(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => onOpenPack(pack.id),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pack.name,
                                            style: textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '배경 ${pack.imageCount}종 · ${pack.category} · ${pack.isFree ? '무료' : '유료'} · ${pack.isPublished ? '공개' : '비공개'}',
                                            style: textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: palette.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
