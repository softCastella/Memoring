import 'dart:convert';
import 'dart:io';

/// 로컬 테스트용 배경 카탈로그.
/// 관리자와 앱이 같은 JSON을 읽고 쓴다.
Future<void> main() async {
  final dataFile = File('server/data/catalog.json');
  await dataFile.parent.create(recursive: true);
  if (!await dataFile.exists()) {
    await dataFile.writeAsString(jsonEncode({'packs': <Object>[]}));
  }

  final servers = <HttpServer>[
    await HttpServer.bind(InternetAddress.anyIPv4, 8090),
  ];
  try {
    servers.add(
      await HttpServer.bind(InternetAddress.anyIPv6, 8090, v6Only: true),
    );
  } catch (error) {
    stdout.writeln('IPv6 bind skipped: $error');
  }

  stdout.writeln('Memoring catalog test server');
  stdout.writeln('  local: http://127.0.0.1:8090/');
  stdout.writeln('  local: http://localhost:8090/');
  for (final ip in await _lanIpv4()) {
    stdout.writeln('  lan:   http://$ip:8090/');
  }
  stdout.writeln('USB 폰은 `adb reverse tcp:8090 tcp:8090` 후 localhost로 접속.');

  await Future.wait([
    for (final server in servers)
      () async {
        await for (final request in server) {
          await _handle(request, dataFile);
        }
      }(),
  ]);
}

Future<void> _handle(HttpRequest request, File dataFile) async {
  _cors(request.response);
  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  final path = request.uri.path;
  try {
    if (request.method == 'GET' && path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'ok': true, 'service': 'memoring-catalog'}));
    } else if (request.method == 'GET' && path == '/') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(await _statusPage(dataFile));
    } else if (request.method == 'GET' && path == '/catalog') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(await dataFile.readAsString());
    } else if (request.method == 'GET' && path.startsWith('/image/')) {
      await _writeImage(request, dataFile, path);
    } else if (request.method == 'PUT' && path == '/catalog') {
      final body = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(jsonEncode({'error': 'JSON object required'}));
      } else {
        final packs = decoded['packs'];
        final nextPacks = packs is List ? packs : <Object>[];
        final existingPacks = await _existingPacks(dataFile);
        if (nextPacks.isEmpty && existingPacks.isNotEmpty) {
          request.response
            ..statusCode = HttpStatus.conflict
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': 'refusing empty catalog overwrite'}));
        } else {
          await _atomicWrite(dataFile, jsonEncode({'packs': nextPacks}));
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'ok': true}));
        }
      }
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(jsonEncode({'error': 'not found'}));
    }
  } catch (error) {
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.write(jsonEncode({'error': '$error'}));
  } finally {
    await request.response.close();
  }
}

Future<String> _statusPage(File dataFile) async {
  final packs = await _existingPacks(dataFile);
  final cards = <String>[];
  for (final pack in packs) {
    if (pack is! Map) {
      continue;
    }
    final packId = '${pack['id'] ?? ''}';
    final images = pack['images'];
    final tiles = <String>[];
    if (images is List) {
      for (final image in images) {
        if (image is! Map) {
          continue;
        }
        final assetId = '${image['id'] ?? ''}';
        if (packId.isEmpty || assetId.isEmpty) {
          continue;
        }
        tiles.add(
          '''<figure>
            <div class="shot">
              <img src="/image/${Uri.encodeComponent(packId)}/${Uri.encodeComponent(assetId)}" alt="${_escape(_imageTitle(image))}" />
              <span class="badge ${_imagePrice(image, pack) == '유료' ? 'paid' : 'free'}">${_escape(_imagePrice(image, pack))}</span>
            </div>
            <figcaption>${_escape(_imageTitle(image))}</figcaption>
          </figure>''',
        );
      }
    }
    cards.add('''
    <section class="pack">
      <header>
        <h2>${_escape(pack['name'] ?? packId)}</h2>
        <p>${pack['isPublished'] == true ? '공개' : '비공개'} · ${_packPrice(pack)} · 이미지 ${_imageCount(pack)}종</p>
      </header>
      <div class="grid">
        ${tiles.isEmpty ? '<p class="empty">이미지가 없습니다.</p>' : tiles.join('\n        ')}
      </div>
    </section>''');
  }
  return '''
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Memoring catalog</title>
  <style>
    :root { color-scheme: light; }
    body { margin: 0; font-family: "Segoe UI", sans-serif; background: #f6eee8; color: #3f342f; }
    main { max-width: 960px; margin: 0 auto; padding: 28px 20px 48px; }
    h1 { font-size: 1.6rem; margin: 0 0 8px; }
    .lead { color: #7a6a63; margin: 0 0 24px; }
    .pack { background: #fff; border-radius: 18px; padding: 18px; margin-bottom: 18px; box-shadow: 0 10px 28px rgba(0,0,0,.06); }
    .pack h2 { margin: 0 0 4px; font-size: 1.15rem; }
    .pack header p { margin: 0 0 14px; color: #7a6a63; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 10px; }
    .grid figure { margin: 0; }
    .shot { position: relative; }
    .grid img { width: 100%; height: 140px; object-fit: cover; border-radius: 12px; background: #efe4dc; display: block; }
    .badge { position: absolute; top: 8px; left: 8px; border-radius: 10px; padding: 3px 8px; font-size: 0.75rem; color: #fff; }
    .badge.free { background: rgba(90,70,62,.8); }
    .badge.paid { background: #c9a4a6; }
    .grid figcaption { margin: 8px 2px 0; font-size: 0.9rem; color: #5a463e; }
    .empty { margin: 0; color: #7a6a63; }
  </style>
</head>
<body>
  <main>
    <h1>Memoring catalog</h1>
    <p class="lead">테스트 서버 GUI입니다. 앱은 이 주소의 JSON이 아니라 아래 미리보기를 보면 됩니다.</p>
    ${cards.isEmpty ? '<p class="empty">아직 등록된 팩이 없습니다. 관리자에서 이미지를 저장하면 여기에 보여요.</p>' : cards.join('\n')}
  </main>
</body>
</html>
''';
}

Future<void> _writeImage(
  HttpRequest request,
  File dataFile,
  String path,
) async {
  final parts = path.substring('/image/'.length).split('/');
  if (parts.length != 2) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({'error': 'not found'}));
    return;
  }
  final packId = Uri.decodeComponent(parts[0]);
  final assetId = Uri.decodeComponent(parts[1]);
  Map? asset;
  for (final pack in await _existingPacks(dataFile)) {
    if (pack is! Map || '${pack['id']}' != packId) {
      continue;
    }
    final images = pack['images'];
    if (images is! List) {
      break;
    }
    for (final image in images) {
      if (image is Map && '${image['id']}' == assetId) {
        asset = image;
        break;
      }
    }
  }
  final raw = asset?['base64Data'] as String? ?? '';
  if (raw.isEmpty) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({'error': 'image not found'}));
    return;
  }
  final mime = asset?['mimeType'] as String? ?? 'image/jpeg';
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.parse(mime)
    ..add(base64Decode(raw));
}

int _imageCount(Map pack) {
  final images = pack['images'];
  return images is List ? images.length : 0;
}

String _imageTitle(Map image) {
  final titled = '${image['title'] ?? ''}'.trim();
  if (titled.isNotEmpty) {
    return titled;
  }
  final fileName = '${image['fileName'] ?? ''}'.replaceAll('\\', '/');
  final base = fileName.split('/').last.trim();
  final dot = base.lastIndexOf('.');
  if (dot > 0) {
    return base.substring(0, dot);
  }
  return base.isEmpty ? 'image' : base;
}

String _imagePrice(Map image, Map pack) {
  if (image.containsKey('isFree')) {
    return image['isFree'] == false ? '유료' : '무료';
  }
  return pack['isFree'] == false ? '유료' : '무료';
}

String _packPrice(Map pack) {
  final images = pack['images'];
  if (images is! List || images.isEmpty) {
    return pack['isFree'] == false ? '유료' : '무료';
  }
  var paid = 0;
  var free = 0;
  for (final image in images) {
    if (image is! Map) {
      continue;
    }
    if (_imagePrice(image, pack) == '유료') {
      paid += 1;
    } else {
      free += 1;
    }
  }
  if (paid == 0) {
    return '무료';
  }
  if (free == 0) {
    return '유료';
  }
  return '일부 유료';
}

String _escape(Object? value) {
  return '$value'
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

Future<List<Object?>> _existingPacks(File dataFile) async {
  if (!await dataFile.exists()) {
    return const [];
  }
  try {
    final decoded = jsonDecode(await dataFile.readAsString());
    if (decoded is Map && decoded['packs'] is List) {
      return List<Object?>.from(decoded['packs'] as List);
    }
  } catch (_) {}
  return const [];
}

Future<void> _atomicWrite(File file, String contents) async {
  final tmp = File('${file.path}.tmp');
  await tmp.writeAsString(contents);
  await tmp.copy(file.path);
  await tmp.delete();
}

void _cors(HttpResponse response) {
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET, PUT, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type')
    ..set('Cache-Control', 'no-store');
}

Future<List<String>> _lanIpv4() async {
  final found = <String>[];
  for (final interface in await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLinkLocal: false,
  )) {
    for (final address in interface.addresses) {
      if (address.isLoopback) {
        continue;
      }
      found.add(address.address);
    }
  }
  return found;
}
