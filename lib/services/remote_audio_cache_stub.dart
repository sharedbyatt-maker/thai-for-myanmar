Future<String?> cacheRemoteAudio(Uri url, {required bool online}) async =>
    online ? url.toString() : null;
