import 'package:flutter/material.dart';

import '../catalog/catalog_store.dart';
import '../config/app_config.dart';
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
    this.onLeave,
  });

  final AdminAuth auth;
  final CatalogStore catalog;
  final VoidCallback onLock;
  final VoidCallback? onLeave;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _menu = 'backgrounds';
  String? _packId;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final framed = constraints.maxWidth >= 960;
            final shell = Row(
              children: [
                _Sidebar(
                  menu: _menu,
                  onSelect: (menu) => setState(() {
                    _menu = menu;
                    if (menu != 'backgrounds') {
                      _packId = null;
                    }
                  }),
                ),
                Expanded(
                  child: ColoredBox(
                    color: palette.background,
                    child: Column(
                      children: [
                        _TopBar(onLock: _lock, onLeave: widget.onLeave),
                        Expanded(child: _body()),
                      ],
                    ),
                  ),
                ),
              ],
            );

            if (!framed) {
              return shell;
            }

            return Padding(
              padding: const EdgeInsets.all(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: shell,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _lock() {
    widget.auth.lock();
    widget.onLock();
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

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.menu, required this.onSelect});

  final String menu;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 232,
      child: ColoredBox(
        color: palette.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 20, 20),
              child: Text(
                '${AppConfig.appName}\n관리자 센터',
                style: textTheme.titleMedium,
              ),
            ),
            _NavItem(
              icon: Icons.space_dashboard_outlined,
              label: '대시보드',
              selected: menu == 'dashboard',
              onTap: () => onSelect('dashboard'),
            ),
            _NavItem(
              icon: Icons.checklist_outlined,
              label: '체크리스트 관리',
              selected: menu == 'checklist',
              onTap: () => onSelect('checklist'),
            ),
            _NavItem(
              icon: Icons.photo_outlined,
              label: '배경 관리',
              selected: menu == 'backgrounds',
              onTap: () => onSelect('backgrounds'),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: '사용자 관리',
              selected: menu == 'users',
              onTap: () => onSelect('users'),
            ),
            _NavItem(
              icon: Icons.campaign_outlined,
              label: '공지사항',
              selected: menu == 'notices',
              onTap: () => onSelect('notices'),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              label: '설정',
              selected: menu == 'settings',
              onTap: () => onSelect('settings'),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('개발 모드 · 로컬 저장', style: textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onLock, this.onLeave});

  final VoidCallback onLock;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 22, 4),
      child: Row(
        children: [
          if (onLeave != null)
            TextButton(
              onPressed: () {
                onLock();
              },
              child: Text(
                '앱으로',
                style: textTheme.labelLarge?.copyWith(color: palette.accent),
              ),
            ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: '관리자',
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'lock') {
                onLock();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'lock', child: Text('나가기')),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: palette.accentSoft,
                  child: Icon(
                    Icons.person_outline,
                    size: 16,
                    color: palette.text,
                  ),
                ),
                const SizedBox(width: 8),
                Text('관리자', style: textTheme.bodyMedium),
                Icon(Icons.keyboard_arrow_down, size: 18, color: palette.textMuted),
              ],
            ),
          ),
        ],
      ),
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
