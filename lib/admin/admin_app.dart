import 'package:flutter/material.dart';

import '../catalog/catalog_store.dart';
import '../models/appearance_settings.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'admin_auth.dart';
import 'admin_shell.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({
    super.key,
    required this.auth,
    required this.catalog,
  });

  final AdminAuth auth;
  final CatalogStore catalog;

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
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
    const palette = AppPalette.rose;
    return ThemeScope(
      palette: palette,
      appearance: AppearanceSettings.defaults(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '체크리스트 관리자 센터',
        theme: buildThemeData(palette),
        home: widget.auth.unlocked
            ? AdminShell(
                auth: widget.auth,
                catalog: widget.catalog,
                onLock: () => setState(() {}),
              )
            : _LoginPage(
                auth: widget.auth,
                controller: _password,
                error: _error,
                busy: _busy,
                onSubmit: _submit,
              ),
      ),
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
}

class _LoginPage extends StatelessWidget {
  const _LoginPage({
    required this.auth,
    required this.controller,
    required this.error,
    required this.busy,
    required this.onSubmit,
  });

  final AdminAuth auth;
  final TextEditingController controller;
  final String error;
  final bool busy;
  final VoidCallback onSubmit;

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
                  Text('체크리스트 관리자 센터', style: textTheme.headlineSmall),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
