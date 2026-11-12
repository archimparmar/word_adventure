import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/theme.dart';


class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _initialized = false;
  // The AdMob unit behind rewardedAdUnitId is of type "Rewarded interstitial";
  // requesting it as RewardedAd fails with "Ad unit doesn't match format".
  RewardedInterstitialAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;
  DateTime? _lastInterstitialTime;
  static const Duration _interstitialCooldown = Duration(seconds: 45);

  // Production AdMob Unit IDs
  String get appId => 'ca-app-pub-5873612031869970~7973233013';

  String get bannerAdUnitId {
    return 'ca-app-pub-5873612031869970/5683158742';
  }

  String get interstitialAdUnitId {
    return 'ca-app-pub-5873612031869970/3236958805';
  }

  String get rewardedAdUnitId {
    return 'ca-app-pub-5873612031869970/9455152297';
  }

  bool get isSupportedPlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (isSupportedPlatform) {
      try {
        final status = await MobileAds.instance.initialize();
        status.adapterStatuses.forEach((name, adapter) {
          debugPrint('[AdMob] init adapter $name: ${adapter.state.name} ${adapter.description}');
        });
        debugPrint('[AdMob] MobileAds initialized.');
        loadRewardedAd();
        loadInterstitialAd();
      } catch (e) {
        debugPrint('[AdMob] MobileAds initialization error: $e');
      }
    }
  }

  static String describeLoadError(LoadAdError error) =>
      'code=${error.code} domain=${error.domain} message=${error.message} '
      'responseInfo=${error.responseInfo}';

  // Failed loads are retried with a growing delay, up to _maxLoadRetries times.
  // A tap on WATCH AD (or the next interstitial trigger) starts a fresh cycle.
  static const int _maxLoadRetries = 4;
  static Duration _retryDelay(int attempt) => Duration(seconds: 15 * (1 << (attempt - 1)));

  // ── REWARDED ADS ──────────────────────────────────────────────────────────
  int _rewardedLoadAttempts = 0;
  Timer? _rewardedRetryTimer;
  LoadAdError? _lastRewardedLoadError;

  void loadRewardedAd() {
    if (!isSupportedPlatform || _rewardedAd != null || _isRewardedAdLoading) return;

    _rewardedRetryTimer?.cancel();
    _isRewardedAdLoading = true;
    debugPrint('[AdMob] Rewarded load request: $rewardedAdUnitId');
    RewardedInterstitialAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          _rewardedLoadAttempts = 0;
          _lastRewardedLoadError = null;
          debugPrint('[AdMob] Rewarded ad loaded: ${ad.responseInfo}');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdLoading = false;
          _lastRewardedLoadError = error;
          debugPrint('[AdMob] Rewarded ad failed to load: ${describeLoadError(error)}');
          if (_rewardedLoadAttempts < _maxLoadRetries) {
            _rewardedLoadAttempts++;
            _rewardedRetryTimer = Timer(_retryDelay(_rewardedLoadAttempts), loadRewardedAd);
          }
        },
      ),
    );
  }

  bool get isRewardedAdReady => isSupportedPlatform ? _rewardedAd != null : true;

  Future<void> showRewardedAd({
    required BuildContext context,
    required VoidCallback onRewardGranted,
    VoidCallback? onAdFailed,
  }) async {
    // If on unsupported platform (like Web or Desktop during dev testing), show simulated ad modal
    // The simulated modal exists only for debug runs on platforms without AdMob.
    // It is never shown on Android/iOS or in release builds.
    if (!isSupportedPlatform) {
      if (kDebugMode) {
        _showSimulatedAdDialog(context, onRewardGranted);
      } else if (onAdFailed != null) {
        onAdFailed();
      }
      return;
    }

    if (_rewardedAd == null) {
      final lastError = _lastRewardedLoadError;
      debugPrint('[AdMob] WATCH AD tapped but no rewarded ad is ready '
          '(loading=$_isRewardedAdLoading, lastError=${lastError == null ? 'none' : describeLoadError(lastError)})');
      _rewardedLoadAttempts = 0;
      loadRewardedAd();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lastError == null
                ? 'Ad is loading, please try again in a moment...'
                : 'No ad available right now (error ${lastError.code}). Please try again later.',
          ),
          backgroundColor: const Color(0xFF1B362A),
          duration: const Duration(seconds: 2),
        ),
      );
      // No simulated/test ad and no reward here: a reward is only granted after
      // a real rewarded ad has been watched.
      return;
    }

    bool rewardEarned = false;
    bool hasHandledCallback = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdMob] Rewarded ad showed full screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob] Rewarded ad dismissed (rewardEarned=$rewardEarned).');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();

        if (rewardEarned && !hasHandledCallback) {
          hasHandledCallback = true;
          onRewardGranted();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        debugPrint('[AdMob] Rewarded ad failed to show: code=${error.code} domain=${error.domain} message=${error.message}');
        if (!hasHandledCallback) {
          hasHandledCallback = true;
          if (onAdFailed != null) {
            onAdFailed();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not play ad. Please try again.'),
                backgroundColor: AppTheme.coral,
              ),
            );
          }
        }
      },
    );

    // Detach the ad before showing so a second tap cannot show (or reward) it twice.
    final ad = _rewardedAd!;
    _rewardedAd = null;
    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
        debugPrint('[AdMob] Rewarded ad reward earned: ${rewardItem.amount} ${rewardItem.type}');
        rewardEarned = true;
      },
    );
  }

  // ── SIMULATED AD DIALOG (FOR DEV / NON-MOBILE PLATFORMS) ───────────────────
  void _showSimulatedAdDialog(BuildContext context, VoidCallback onRewardGranted) {
    bool completed = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _SimulatedAdModal(
          onComplete: () {
            completed = true;
            Navigator.pop(dialogContext);
          },
          onCloseEarly: () {
            Navigator.pop(dialogContext);
          },
        );
      },
    ).then((_) {
      if (completed) {
        onRewardGranted();
      }
    });
  }

  // ── INTERSTITIAL ADS ───────────────────────────────────────────────────────
  int _interstitialLoadAttempts = 0;
  Timer? _interstitialRetryTimer;

  void loadInterstitialAd() {
    if (!isSupportedPlatform || _interstitialAd != null || _isInterstitialAdLoading) return;

    _interstitialRetryTimer?.cancel();
    _isInterstitialAdLoading = true;
    debugPrint('[AdMob] Interstitial load request: $interstitialAdUnitId');
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          _interstitialLoadAttempts = 0;
          debugPrint('[AdMob] Interstitial ad loaded: ${ad.responseInfo}');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialAdLoading = false;
          debugPrint('[AdMob] Interstitial ad failed to load: ${describeLoadError(error)}');
          if (_interstitialLoadAttempts < _maxLoadRetries) {
            _interstitialLoadAttempts++;
            _interstitialRetryTimer = Timer(_retryDelay(_interstitialLoadAttempts), loadInterstitialAd);
          }
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (!isSupportedPlatform) return;

    final now = DateTime.now();
    if (_lastInterstitialTime != null &&
        now.difference(_lastInterstitialTime!) < _interstitialCooldown) {
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('[AdMob] Interstitial trigger: no ad ready (loading=$_isInterstitialAdLoading).');
      _interstitialLoadAttempts = 0;
      loadInterstitialAd();
      return;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdMob] Interstitial ad showed full screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob] Interstitial ad dismissed.');
        ad.dispose();
        _lastInterstitialTime = DateTime.now();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] Interstitial ad failed to show: code=${error.code} domain=${error.domain} message=${error.message}');
        ad.dispose();
        loadInterstitialAd();
      },
    );

    ad.show();
  }
}

// --- Simulated Ad Modal for testing environment ---
class _SimulatedAdModal extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onCloseEarly;

  const _SimulatedAdModal({
    required this.onComplete,
    required this.onCloseEarly,
  });

  @override
  State<_SimulatedAdModal> createState() => _SimulatedAdModalState();
}

class _SimulatedAdModalState extends State<_SimulatedAdModal>
    with SingleTickerProviderStateMixin {
  int _secondsLeft = 3;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _secondsLeft),
    )..forward();

    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft > 0) {
        _startCountdown();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canReward = _secondsLeft <= 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF10152F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD21C), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD21C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'TEST REWARDED AD',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: widget.onCloseEarly,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFFD21C), size: 64),
            const SizedBox(height: 12),
            Text(
              canReward ? 'Ad Completed! Claim Reward' : 'Watching Test Ad...',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _animController.value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD21C)),
                    minHeight: 8,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: canReward ? widget.onComplete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                disabledBackgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                canReward ? 'CLAIM REWARD' : 'WAIT ( s)',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Banner pinned to the bottom of a screen (Scaffold.bottomNavigationBar) ---
// Takes no space beyond the system inset until a banner has actually loaded.
class AdBannerBar extends StatelessWidget {
  const AdBannerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      top: false,
      child: Center(heightFactor: 1, child: AdBannerWidget()),
    );
  }
}

// --- Banner Ad Widget ---
class AdBannerWidget extends StatefulWidget {
  final AdSize adSize;
  const AdBannerWidget({super.key, this.adSize = AdSize.banner});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (AdService().isSupportedPlatform) {
      _bannerAd = BannerAd(
        adUnitId: AdService().bannerAdUnitId,
        size: widget.adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('[AdMob] Banner ad loaded: ${ad.responseInfo}');
            if (mounted) {
              setState(() {
                _isLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('[AdMob] Banner ad failed to load: ${AdService.describeLoadError(error)}');
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAd = null;
              });
            }
          },
        ),
      );
      debugPrint('[AdMob] Banner load request: ${AdService().bannerAdUnitId}');
      _bannerAd!.load();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
