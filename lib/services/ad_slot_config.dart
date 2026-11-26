enum AdPlacement {
  banner,
  native,
  interstitial,
  rewarded,
  rewardedInterstitial,
  appOpen;

  bool get fullScreen => this != banner && this != native;
}

class AndroidAdsConfig {
  const AndroidAdsConfig(this.values);
  final Map<String, dynamic> values;

  static final testDevicePattern = RegExp(r'^[A-F0-9]{24}$');
  bool get enabled => values['enabled'] == true;
  bool get deliversLive => enabled && values['delivery'] == 'live';

  bool matchesTestDevice(String code) =>
      enabled &&
      values['delivery'] == 'test' &&
      testDevicePattern.hasMatch(code) &&
      values['testDevice'] == code;

  bool formatEnabled(AdPlacement placement) {
    final formats = values['formats'];
    if (formats is! Map) return false;
    final format = formats[placement.name];
    return format is Map && format['enabled'] == true;
  }

  static final adUnitPattern = RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]{10}$');

  int get cooldownMinutes => _number('cooldownMinutes', 8, 5, 120);
  int get dailyLimit => _number('dailyLimit', 3, 1, 5);
  int get lessonInterval => _number('lessonInterval', 4, 4, 30);

  int _number(String key, int fallback, int min, int max) {
    final value = values[key];
    return value is int ? value.clamp(min, max) : fallback;
  }

  String? unit(AdPlacement placement) {
    final formats = values['formats'];
    if (!deliversLive || formats is! Map || !formatEnabled(placement)) {
      return null;
    }
    final format = formats[placement.name] as Map;
    final id = format['unitId'];
    return id is String && adUnitPattern.hasMatch(id) ? id : null;
  }
}

class AdFrequency {
  static String dayKey(DateTime now) => '${now.year}-${now.month}-${now.day}';

  static bool canShow({
    required AdPlacement placement,
    required DateTime now,
    required int? lastShown,
    required int? lastAppOpen,
    required String? day,
    required int count,
    required int cooldownMinutes,
    required int dailyLimit,
  }) {
    final time = now.millisecondsSinceEpoch;
    if (lastShown != null &&
        time - lastShown < Duration(minutes: cooldownMinutes).inMilliseconds) {
      return false;
    }
    if (day == dayKey(now) && count >= dailyLimit) return false;
    return placement != AdPlacement.appOpen ||
        lastAppOpen == null ||
        time - lastAppOpen >= const Duration(hours: 24).inMilliseconds;
  }
}
