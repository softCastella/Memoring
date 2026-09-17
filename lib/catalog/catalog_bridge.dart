import 'catalog_bridge_stub.dart'
    if (dart.library.html) 'catalog_bridge_web.dart'
    as impl;

/// 앱이 관리자(기본 8081) 카탈로그를 받기 위해 숨은 브릿지를 연다.
void startCatalogBridge({
  required Future<void> Function(Map<String, dynamic> body) onCatalog,
}) {
  impl.startCatalogBridge(onCatalog: onCatalog);
}
