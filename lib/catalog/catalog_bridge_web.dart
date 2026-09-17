// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

import '../config/app_config.dart';

const _messageType = 'memoring.catalog';

void startCatalogBridge({
  required Future<void> Function(Map<String, dynamic> body) onCatalog,
}) {
  html.window.onMessage.listen((event) {
    if (event.origin != AppConfig.adminOrigin) {
      return;
    }
    final data = event.data;
    if (data is! String) {
      return;
    }
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map || decoded['type'] != _messageType) {
        return;
      }
      final payload = decoded['payload'];
      if (payload is Map) {
        onCatalog(Map<String, dynamic>.from(payload));
      }
    } catch (_) {}
  });

  final iframe = html.IFrameElement()
    ..src = '${AppConfig.adminOrigin}/catalog_bridge.html'
    ..style.border = '0'
    ..style.width = '0'
    ..style.height = '0'
    ..style.position = 'absolute'
    ..style.left = '-9999px';
  html.document.body?.append(iframe);
}

void publishCatalogToApp(Map<String, dynamic> payload) {}

void listenForCatalogStorage(void Function() onChange) {}
