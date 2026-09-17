import 'package:flutter/material.dart';

import '../catalog/catalog_store.dart';
import '../models/appearance_settings.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'admin_auth.dart';
import 'admin_host.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({
    super.key,
    required this.auth,
    required this.catalog,
  });

  final AdminAuth auth;
  final CatalogStore catalog;

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
        home: AdminHost(auth: auth, catalog: catalog),
      ),
    );
  }
}
