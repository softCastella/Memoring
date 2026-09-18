import 'package:flutter/material.dart';

import '../catalog/catalog_store.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'admin_auth.dart';
import 'admin_shell.dart';

/// 로그인과 배경 관리 본문. 앱과 같은 `CatalogStore`를 쓰면 공개 팩이 스토어에 바로 보인다.
class AdminHost extends StatefulWidget {
  const AdminHost({
    super.key,
    required this.auth,
    required this.catalog,
    this.onLeave,
  });

  final AdminAuth auth;
  final CatalogStore catalog;
  final VoidCallback? onLeave;

  @override
  State<AdminHost> createState() => _AdminHostState();
}

class _AdminHostState extends State<AdminHost> {
  final _password = TextEditingController();
  String _error = '';
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.auth.unlocked) {
      return AdminShell(
        auth: widget.auth,
        catalog: widget.catalog,
        onLock: _lock,
        onLeave: widget.onLeave,
      );
    }
    return AdminLoginPage(
      auth: widget.auth,
      controller: _password,
      error: _error,
      busy: _busy,
      onSubmit: _submit,
      onCancel: widget.onLeave,
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final message = await widget.auth.unlock(_password.text);
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  void _lock() {
    widget.auth.lock();
    _password.clear();
    if (widget.onLeave != null) {
      widget.onLeave!();
      return;
    }
    setState(() {});
  }
}

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({
    super.key,
    required this.auth,
    required this.controller,
    required this.error,
    required this.busy,
    required this.onSubmit,
    this.onCancel,
  });

  final AdminAuth auth;
  final TextEditingController controller;
  final String error;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${AppConfig.appName} 관리자 센터',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth.needsSetup
                        ? '개발 모드입니다. 이 브라우저에만 저장될 운영 비밀번호를 정해 주세요. 소스 코드에는 넣지 않습니다.'
                        : auth.hasDefinedPassword
                        ? '실행 시 전달한 관리자 비밀번호로 들어가 주세요.'
                        : '이 기기에 저장된 개발용 비밀번호를 입력해 주세요.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    onSubmitted: (_) => onSubmit(),
                    decoration: const InputDecoration(hintText: '비밀번호'),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      error,
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB46868),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: busy ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(auth.needsSetup ? '비밀번호 저장 후 입장' : '입장'),
                  ),
                  if (onCancel != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('앱으로 돌아가기'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
