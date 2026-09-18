import 'package:flutter/material.dart';

import 'admin/admin_app.dart';
import 'admin/admin_auth.dart';
import 'catalog/catalog_client.dart';
import 'catalog/catalog_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AdminAuth();
  await auth.load();
  final catalog = CatalogStore(client: CatalogClient());
  await catalog.load();
  runApp(AdminApp(auth: auth, catalog: catalog));
}
