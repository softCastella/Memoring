import 'package:flutter/material.dart';

import '../catalog/catalog_store.dart';
import '../theme/app_theme.dart';
import 'admin_auth.dart';
import 'pack_editor_screen.dart';
import 'pack_list_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.auth,
    required this.catalog,
    required this.onLock,
  });

  final AdminAuth auth;
  final CatalogStore catalog;
  final VoidCallback onLock;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _menu = 'backgrounds';
  String? _packId;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: palette.background,
      body: Row(
        children: [
          SizedBox(
            width: 232,
            child: ColoredBox(
              color: palette.surface,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Text(
                        '체크리스트\n관리자 센터',
                        style: textTheme.titleMedium,
                      ),
                    ),
                    _NavItem(
                      icon: Icons.space_dashboard_outlined,
                      label: '대시보드',
                      selected: _menu == 'dashboard',
                      onTap: () => setState(() {
                        _menu = 'dashboard';
                        _packId = null;
                      }),
                    ),
                    _NavItem(
                      icon: Icons.checklist_outlined,
                      label: '체크리스트 관리',
                      selected: _menu == 'checklist',
                      onTap: () => setState(() {
                        _menu = 'checklist';
                        _packId = null;
                      }),
                    ),
                    _NavItem(
                      icon: Icons.photo_outlined,
                      label: '배경 관리',
                      selected: _menu == 'backgrounds',
                      onTap: () => setState(() {
                        _menu = 'backgrounds';
                      }),
                    ),
                    _NavItem(
                      icon: Icons.person_outline,
                      label: '사용자 관리',
                      selected: _menu == 'users',
                      onTap: () => setState(() {
                        _menu = 'users';
                        _packId = null;
                      }),
                    ),
                    _NavItem(
                      icon: Icons.campaign_outlined,
                      label: '공지사항',
                      selected: _menu == 'notices',
                      onTap: () => setState(() {
                        _menu = 'notices';
                        _packId = null;
                      }),
                    ),
                    _NavItem(
                      icon: Icons.settings_outlined,
                      label: '설정',
                      selected: _menu == 'settings',
                      onTap: () => setState(() {
                        _menu = 'settings';
                        _packId = null;
                      }),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '개발 모드 · 로컬 저장',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                ColoredBox(
                  color: palette.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                    child: Row(
                      children: [
                        Text('체크리스트 관리자 센터', style: textTheme.titleSmall),
                        const Spacer(),
                        Text('관리자', style: textTheme.bodyMedium),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {
                            widget.auth.lock();
                            widget.onLock();
                          },
                          child: const Text('나가기'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_menu != 'backgrounds') {
      return _Placeholder(menu: _menu);
    }
    if (_packId == null) {
      return PackListScreen(
        catalog: widget.catalog,
        onOpenPack: (id) => setState(() => _packId = id),
      );
    }
    return PackEditorScreen(
      catalog: widget.catalog,
      packId: _packId!,
      onBack: () => setState(() => _packId = null),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? palette.highlight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? palette.accent : palette.textMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: selected ? palette.accent : palette.text,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.menu});

  final String menu;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = ThemeScope.of(context).palette;
    final copy = switch (menu) {
      'users' => '사용자 개인 할 일·감정 기록은 운영자가 볼 수 없습니다.',
      'checklist' => '사용자 체크리스트 조회는 만들지 않습니다.',
      _ => '이 메뉴는 이후 단계에서 연결합니다. 지금은 배경 관리만 사용할 수 있어요.',
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(
          copy,
          style: textTheme.bodyLarge?.copyWith(color: palette.textMuted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
