import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_slot_config.dart';
import 'remote_controls.dart';

const _enabled = bool.fromEnvironment('ENABLE_ADS');
const _production = bool.fromEnvironment('ADMOB_PRODUCTION');
bool get _supported =>
    _enabled &&
    defaultTargetPlatform == TargetPlatform.android &&
    (!kReleaseMode || _production);
const _testIds = {
  AdPlacement.banner: 'ca-app-pub-3940256099942544/6300978111',
  AdPlacement.native: 'ca-app-pub-3940256099942544/2247696110',
  AdPlacement.interstitial: 'ca-app-pub-3940256099942544/1033173712',
  AdPlacement.rewarded: 'ca-app-pub-3940256099942544/5224354917',
  AdPlacement.rewardedInterstitial: 'ca-app-pub-3940256099942544/5354046379',
  AdPlacement.appOpen: 'ca-app-pub-3940256099942544/9257395921',
};

final _ads = _MobileAdsController();

void initializeAds() {
  if (_supported) unawaited(_ads.initialize());
}

class _MobileAdsController extends ChangeNotifier {
  final _loaded = <AdPlacement, ({AdWithoutView ad, DateTime time})>{};
  final _loading = <AdPlacement>{};
  final _retryAfter = <AdPlacement, DateTime>{};
  SharedPreferences? _prefs;
  bool _ready = false;
  bool _showing = false;
  bool privacyOptionsRequired = false;

  AndroidAdsConfig get config => RemoteControls.instance.androidAds;
  bool get _hasUnits =>
      !kReleaseMode ||
      AdPlacement.values.any((placement) => config.unit(placement) != null);

  String? _unit(AdPlacement placement) {
    if (!_ready) return null;
    return kReleaseMode ? config.unit(placement) : _testIds[placement];
  }

  Future<void> initialize() async {
    try {
      final consent = ConsentInformation.instance;
      final update = Completer<bool>();
      consent.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => update.complete(true),
        (_) => update.complete(false),
      );
      if (await update.future) {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
      }
      privacyOptionsRequired =
          await consent.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!_hasUnits || !await consent.canRequestAds()) {
        notifyListeners();
        return;
      }
      _prefs = await SharedPreferences.getInstance();
      await MobileAds.instance.initialize();
      _ready = true;
      notifyListeners();
      preload();
    } catch (_) {
      // Ads are optional. A failed SDK or consent request leaves them off.
      notifyListeners();
    }
  }

  void _preload(AdPlacement placement) {
    final id = _unit(placement);
    if (id == null || _showing || _loading.contains(placement)) return;
    final now = DateTime.now();
    final last = _loaded[placement];
    if (last != null &&
        now.difference(last.time) < const Duration(minutes: 45)) {
      return;
    }
    if (_retryAfter[placement]?.isAfter(now) ?? false) return;
    final expired = _loaded.remove(placement);
    if (expired != null) unawaited(expired.ad.dispose());
    _loading.add(placement);
    void loaded(AdWithoutView ad) {
      _loading.remove(placement);
      if (_unit(placement) != id) {
        unawaited(ad.dispose());
        return;
      }
      _loaded[placement] = (ad: ad, time: DateTime.now());
      notifyListeners();
    }

    void failed(LoadAdError _) {
      _loading.remove(placement);
      _retryAfter[placement] = DateTime.now().add(const Duration(minutes: 2));
    }

    const request = AdRequest();
    final Future<void> load;
    switch (placement) {
      case AdPlacement.interstitial:
        load = InterstitialAd.load(
          adUnitId: id,
          request: request,
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: loaded,
            onAdFailedToLoad: failed,
          ),
        );
      case AdPlacement.rewarded:
        load = RewardedAd.load(
          adUnitId: id,
          request: request,
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: loaded,
            onAdFailedToLoad: failed,
          ),
        );
      case AdPlacement.rewardedInterstitial:
        load = RewardedInterstitialAd.load(
          adUnitId: id,
          request: request,
          rewardedInterstitialAdLoadCallback:
              RewardedInterstitialAdLoadCallback(
                onAdLoaded: loaded,
                onAdFailedToLoad: failed,
              ),
        );
      case AdPlacement.appOpen:
        load = AppOpenAd.load(
          adUnitId: id,
          request: request,
          adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: loaded,
            onAdFailedToLoad: failed,
          ),
        );
      case AdPlacement.banner:
      case AdPlacement.native:
        _loading.remove(placement);
        return;
    }
    unawaited(
      load.catchError((Object _) {
        _loading.remove(placement);
        _retryAfter[placement] = DateTime.now().add(const Duration(minutes: 2));
      }),
    );
  }

  void preload() {
    for (final placement in AdPlacement.values.where(
      (format) => format.fullScreen,
    )) {
      _preload(placement);
    }
  }

  bool canShow(AdPlacement placement) {
    final item = _loaded[placement];
    final prefs = _prefs;
    if (_unit(placement) == null || item == null || _showing || prefs == null) {
      return false;
    }
    final now = DateTime.now();
    if (now.difference(item.time) >= const Duration(minutes: 45)) return false;
    return AdFrequency.canShow(
      placement: placement,
      now: now,
      lastShown: prefs.getInt('ads.lastShown'),
      lastAppOpen: prefs.getInt('ads.lastAppOpen'),
      day: prefs.getString('ads.day'),
      count: prefs.getInt('ads.count') ?? 0,
      cooldownMinutes: config.cooldownMinutes,
      dailyLimit: config.dailyLimit,
    );
  }

  void _recordImpression(AdPlacement placement) {
    final prefs = _prefs!;
    final now = DateTime.now();
    final day = AdFrequency.dayKey(now);
    final count = prefs.getString('ads.day') == day
        ? prefs.getInt('ads.count') ?? 0
        : 0;
    unawaited(prefs.setInt('ads.lastShown', now.millisecondsSinceEpoch));
    unawaited(prefs.setString('ads.day', day));
    unawaited(prefs.setInt('ads.count', count + 1));
    if (placement == AdPlacement.appOpen) {
      unawaited(prefs.setInt('ads.lastAppOpen', now.millisecondsSinceEpoch));
    }
  }

  Future<bool> show(AdPlacement placement) async {
    if (!canShow(placement)) return false;
    final ad = _loaded.remove(placement)!.ad;
    _showing = true;
    final done = Completer<bool>();
    var earned = false;
    var displayed = false;
    void record(AdWithoutView _) {
      if (displayed) return;
      displayed = true;
      _recordImpression(placement);
    }

    void finish(AdWithoutView _) {
      if (!done.isCompleted) done.complete(earned);
    }

    void fail(AdWithoutView _, AdError error) {
      finish(ad);
    }

    try {
      switch (ad) {
        case InterstitialAd():
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: record,
            onAdDismissedFullScreenContent: finish,
            onAdFailedToShowFullScreenContent: fail,
          );
          await ad.show();
        case RewardedAd():
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: record,
            onAdDismissedFullScreenContent: finish,
            onAdFailedToShowFullScreenContent: fail,
          );
          await ad.show(onUserEarnedReward: (_, _) => earned = true);
        case RewardedInterstitialAd():
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: record,
            onAdDismissedFullScreenContent: finish,
            onAdFailedToShowFullScreenContent: fail,
          );
          await ad.show(onUserEarnedReward: (_, _) => earned = true);
        case AppOpenAd():
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: record,
            onAdDismissedFullScreenContent: finish,
            onAdFailedToShowFullScreenContent: fail,
          );
          await ad.show();
        default:
          finish(ad);
      }
      return await done.future.timeout(const Duration(minutes: 2));
    } catch (_) {
      return earned;
    } finally {
      await ad.dispose().catchError((Object _) {});
      _showing = false;
      notifyListeners();
      preload();
    }
  }

  Future<void> changePrivacyOptions() async {
    final previous = _ready;
    _ready = false;
    for (final item in _loaded.values) {
      unawaited(item.ad.dispose());
    }
    _loaded.clear();
    notifyListeners();
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
      final allowed =
          _hasUnits && await ConsentInformation.instance.canRequestAds();
      if (allowed && !previous) {
        _prefs = await SharedPreferences.getInstance();
        await MobileAds.instance.initialize();
      }
      _ready = allowed;
    } catch (_) {
      // Keep ads off until consent can be verified.
    }
    notifyListeners();
    preload();
  }
}

void preloadLessonAds() => _ads.preload();

void maybeShowAppOpenAd() {
  unawaited(_ads.show(AdPlacement.appOpen));
  _ads.preload();
}

Future<void> showLessonTransitionAd(
  BuildContext context, {
  required int completedLessons,
  required Future<void> Function()? onReward,
}) async {
  if (completedLessons < _ads.config.lessonInterval ||
      completedLessons % _ads.config.lessonInterval != 0) {
    return;
  }
  if (onReward != null && _ads.canShow(AdPlacement.rewardedInterstitial)) {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('အပိုလေ့ကျင့်ခန်း ၁ ခု'),
        content: const Text(
          'ကြော်ငြာကို ပြီးအောင်ကြည့်လျှင် အပိုလေ့ကျင့်ခန်း ၁ ခု ရပါမယ်။ '
          'ကျော်ပြီး နောက်သင်ခန်းစာ ဆက်နိုင်ပါတယ်။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ကျော်ပြီး ဆက်မယ်'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ကြော်ငြာကြည့်မယ်'),
          ),
        ],
      ),
    );
    if (accepted == true &&
        context.mounted &&
        await _ads.show(AdPlacement.rewardedInterstitial) &&
        context.mounted) {
      await onReward();
    }
    return;
  }
  await _ads.show(AdPlacement.interstitial);
}

class AdBonusButton extends StatelessWidget {
  const AdBonusButton({super.key, required this.onReward});
  final Future<void> Function() onReward;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _ads,
    builder: (context, _) => _ads.canShow(AdPlacement.rewarded)
        ? OutlinedButton.icon(
            icon: const Icon(Icons.ondemand_video_outlined),
            label: const Text('ကြော်ငြာကြည့်ပြီး အပိုလေ့ကျင့်ခန်း ၁ ခု ရယူမယ်'),
            onPressed: () async {
              if (await _ads.show(AdPlacement.rewarded) && context.mounted) {
                await onReward();
              }
            },
          )
        : const SizedBox.shrink(),
  );
}

class AdPrivacyOptions extends StatelessWidget {
  const AdPrivacyOptions({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _ads,
    builder: (context, _) => _ads.privacyOptionsRequired
        ? ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('ကြော်ငြာ ကိုယ်ရေးအချက်အလက် ရွေးချယ်မှု'),
            onTap: _ads.changePrivacyOptions,
          )
        : const SizedBox.shrink(),
  );
}

class InlineAdSlot extends StatelessWidget {
  const InlineAdSlot({super.key, this.native = false});
  final bool native;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _ads,
    builder: (context, _) {
      final id = _ads._unit(native ? AdPlacement.native : AdPlacement.banner);
      if (id == null || MediaQuery.sizeOf(context).width < 320) {
        return const SizedBox.shrink();
      }
      return _InlineAd(key: ValueKey((id, native)), id: id, native: native);
    },
  );
}

class _InlineAd extends StatefulWidget {
  const _InlineAd({super.key, required this.id, required this.native});
  final String id;
  final bool native;

  @override
  State<_InlineAd> createState() => _InlineAdState();
}

class _InlineAdState extends State<_InlineAd> {
  AdWithView? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    void loaded(Ad _) {
      if (mounted) setState(() => _loaded = true);
    }

    void failed(Ad ad, LoadAdError _) {
      if (!mounted || _ad != ad) return;
      _ad = null;
      unawaited(ad.dispose());
    }

    final ad = widget.native
        ? NativeAd(
            adUnitId: widget.id,
            request: const AdRequest(),
            nativeTemplateStyle: NativeTemplateStyle(
              templateType: TemplateType.small,
            ),
            listener: NativeAdListener(
              onAdLoaded: loaded,
              onAdFailedToLoad: failed,
            ),
          )
        : BannerAd(
            adUnitId: widget.id,
            request: const AdRequest(),
            size: AdSize.banner,
            listener: BannerAdListener(
              onAdLoaded: loaded,
              onAdFailedToLoad: failed,
            ),
          );
    _ad = ad;
    unawaited(
      ad.load().catchError((Object _) {
        if (!mounted || _ad != ad) return;
        _ad = null;
        unawaited(ad.dispose());
      }),
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 320,
          height: widget.native ? 100 : 50,
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
