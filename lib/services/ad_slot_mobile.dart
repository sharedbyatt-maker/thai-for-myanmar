import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _adsEnabled = bool.fromEnvironment('ENABLE_ADS', defaultValue: false);
const _productionMode = bool.fromEnvironment(
  'ADMOB_PRODUCTION',
  defaultValue: false,
);
const _productionBannerId = String.fromEnvironment('ADMOB_ANDROID_BANNER_ID');
const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';

bool get _canShowAds {
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android ||
      !_adsEnabled) {
    return false;
  }
  if (kReleaseMode) return _productionMode && _productionBannerId.isNotEmpty;
  return true;
}

String get _bannerId =>
    kReleaseMode && _productionMode ? _productionBannerId : _testBannerId;

Future<void> initializeAds() async {
  if (!_canShowAds) return;
  try {
    await MobileAds.instance.initialize();
  } catch (_) {
    // Ad setup failure must never block learning.
  }
}

class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key});

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (_canShowAds) _load();
  }

  void _load() {
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: _bannerId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() {
            _ad = loaded as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (failed, _) {
          failed.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    _ad = ad;
    ad.load();
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
