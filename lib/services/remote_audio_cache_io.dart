import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<String?> cacheRemoteAudio(Uri url, {required bool online}) async {
  final base = await getApplicationSupportDirectory();
  final cache = Directory('${base.path}/chang-thai-audio');
  final filename = url.pathSegments.last;
  final file = File('${cache.path}/$filename');
  if (await file.exists() && await file.length() > 0)
    return file.uri.toString();
  if (!online) return null;

  final client = http.Client();
  try {
    final response = await client.send(http.Request('GET', url));
    if (response.statusCode != 200) return null;
    const limit = 5 * 1024 * 1024;
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > limit) return null;
      bytes.addAll(chunk);
    }
    if (bytes.length < 4) return null;
    final id3 = bytes[0] == 73 && bytes[1] == 68 && bytes[2] == 51;
    final frameSync = bytes[0] == 255 && (bytes[1] & 224) == 224;
    if (!id3 && !frameSync) return null;
    await cache.create(recursive: true);
    final temp = File('${file.path}.${Random.secure().nextInt(1 << 32)}.tmp');
    try {
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
    return file.uri.toString();
  } finally {
    client.close();
  }
}
