import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../../../core/firebase_manager.dart';

/// Comprehensive ad management for Synther with mediation and revenue optimization
class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // Banner ad instances
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  
  // Interstitial ad instances
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  
  // Rewarded ad instances
  RewardedAd? _rewardedAd;
  bool _isRewardedReady = false;
  
  // Ad configuration
  bool _adsEnabled = true;
  DateTime? _lastInterstitialShow;
  DateTime? _lastRewardedShow;
  int _sessionCount = 0;
  int _interstitialShowCount = 0;
  
  // Frequency capping (prevent ad fatigue)
  static const Duration _interstitialCooldown = Duration(minutes: 3);
  static const Duration _rewardedCooldown = Duration(minutes: 1);
  static const int _maxInterstitialsPerSession = 4;

  /// Initialize AdMob with test or production ad unit IDs
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      
      // Request App Tracking Transparency (iOS)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final trackingStatus = await MobileAds.instance.requestTrackingAuthorization();
        print('ATT Status: $trackingStatus');
      }
      
      // Set up mediation partners (if configured)
      await _configureMediation();
      
      // Preload ads
      await _loadAllAds();
      
      _sessionCount++;
      print('AdMob initialized successfully');
      
      // Log initialization to Firebase
      await FirebaseManager().logEvent('admob_initialized', parameters: {
        'session_count': _sessionCount,
      });
    } catch (e) {
      print('AdMob initialization error: $e');
      _adsEnabled = false;
    }
  }

  /// Configure mediation networks for maximum fill rate and eCPM
  Future<void> _configureMediation() async {
    // Configure mediation waterfall
    // In production, this would be done via AdMob dashboard
    
    // Log mediation setup
    await FirebaseManager().logEvent('mediation_configured', parameters: {
      'networks': ['admob', 'meta_audience_network'], // Add as configured
    });
  }

  /// Get appropriate ad unit IDs based on platform and build mode
  String get _bannerAdUnitId {
    if (kDebugMode) {
      // Test ad unit IDs
      return defaultTargetPlatform == TargetPlatform.android
          ? 'ca-app-pub-3940256099942544/6300978111' // Android test banner
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner
    } else {
      // Production ad unit IDs - REPLACE WITH YOUR ACTUAL IDs
      return defaultTargetPlatform == TargetPlatform.android
          ? 'ca-app-pub-YOUR_PUBLISHER_ID/ANDROID_BANNER'
          : 'ca-app-pub-YOUR_PUBLISHER_ID/IOS_BANNER';
    }
  }

  String get _interstitialAdUnitId {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.android
          ? 'ca-app-pub-3940256099942544/1033173712' // Android test interstitial
          : 'ca-app-pub-3940256099942544/4411468910'; // iOS test interstitial
    } else {
      return defaultTargetPlatform == TargetPlatform.android
          ? 'ca-app-pub-YOUR_PUBLISHER_ID/ANDROID_INTERSTITIAL'
          : 'ca-app-pub-YOUR_PUBLISHER_ID/IOS_INTERSTITIAL';
    }
  }

  String get _rewardedAdUnitId {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.android
          ? 'ca-app-pub-3940256099942544/5224354917' // Android test rewarded
          : 'ca-app-pub-3940256099942544/1712485313'; // iOS test rewarded
    } else {
      return defaultTargetPlatform == TargetPlatform.android
          ? 'ca-app-pub-YOUR_PUBLISHER_ID/ANDROID_REWARDED'
          : 'ca-app-pub-YOUR_PUBLISHER_ID/IOS_REWARDED';
    }
  }

  /// Load all ad types
  Future<void> _loadAllAds() async {
    await Future.wait([
      _loadBannerAd(),
      _loadInterstitialAd(),
      _loadRewardedAd(),
    ]);
  }

  /// Load banner ad for main screen
  Future<void> _loadBannerAd() async {
    if (!_adsEnabled || _shouldHideAds()) return;

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          print('Banner ad loaded');
          
          FirebaseManager().logEvent('ad_loaded', parameters: {
            'ad_type': 'banner',
            'ad_unit_id': _bannerAdUnitId,
          });
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoaded = false;
          ad.dispose();
          _bannerAd = null;
          print('Banner ad failed to load: $error');
          
          FirebaseManager().logEvent('ad_load_failed', parameters: {
            'ad_type': 'banner',
            'error_code': error.code,
            'error_message': error.message,
          });
          
          // Retry after delay
          Future.delayed(const Duration(minutes: 1), _loadBannerAd);
        },
        onAdOpened: (ad) {
          FirebaseManager().logEvent('ad_clicked', parameters: {
            'ad_type': 'banner',
          });
        },
      ),
    );

    await _bannerAd!.load();
  }

  /// Load interstitial ad for session breaks
  Future<void> _loadInterstitialAd() async {
    if (!_adsEnabled || _shouldHideAds()) return;

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          print('Interstitial ad loaded');
          
          FirebaseManager().logEvent('ad_loaded', parameters: {
            'ad_type': 'interstitial',
          });

          // Set up callbacks
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _interstitialShowCount++;
              _lastInterstitialShow = DateTime.now();
              
              FirebaseManager().logEvent('ad_shown', parameters: {
                'ad_type': 'interstitial',
                'show_count': _interstitialShowCount,
              });
            },
            onAdDismissedFullScreenContent: (ad) {
              _interstitialAd?.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              
              FirebaseManager().logEvent('ad_dismissed', parameters: {
                'ad_type': 'interstitial',
              });

              // Preload next interstitial
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _interstitialAd?.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              
              FirebaseManager().logEvent('ad_show_failed', parameters: {
                'ad_type': 'interstitial',
                'error_code': error.code,
                'error_message': error.message,
              });
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialReady = false;
          
          FirebaseManager().logEvent('ad_load_failed', parameters: {
            'ad_type': 'interstitial',
            'error_code': error.code,
            'error_message': error.message,
          });
          
          // Retry after delay
          Future.delayed(const Duration(minutes: 2), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Load rewarded ad for premium feature trials
  Future<void> _loadRewardedAd() async {
    if (!_adsEnabled) return; // Always load rewarded ads even for premium users

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          print('Rewarded ad loaded');
          
          FirebaseManager().logEvent('ad_loaded', parameters: {
            'ad_type': 'rewarded',
          });
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _isRewardedReady = false;
          
          FirebaseManager().logEvent('ad_load_failed', parameters: {
            'ad_type': 'rewarded',
            'error_code': error.code,
            'error_message': error.message,
          });
          
          // Retry after delay
          Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
        },
      ),
    );
  }

  /// Show banner ad widget
  Widget? getBannerAdWidget() {
    if (!_adsEnabled || _shouldHideAds() || !_isBannerLoaded || _bannerAd == null) {
      return null;
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// Show interstitial ad with frequency capping
  Future<bool> showInterstitialAd({String? source}) async {
    if (!_adsEnabled || 
        _shouldHideAds() || 
        !_isInterstitialReady || 
        _interstitialAd == null ||
        !_canShowInterstitial()) {
      return false;
    }

    await FirebaseManager().logEvent('ad_request', parameters: {
      'ad_type': 'interstitial',
      'source': source ?? 'unknown',
    });

    await _interstitialAd!.show();
    return true;
  }

  /// Show rewarded ad with callback
  Future<bool> showRewardedAd({
    required String source,
    required Function(RewardItem reward) onReward,
    Function()? onRewardFailed,
  }) async {
    if (!_adsEnabled || !_isRewardedReady || _rewardedAd == null || !_canShowRewarded()) {
      onRewardFailed?.call();
      return false;
    }

    await FirebaseManager().logEvent('ad_request', parameters: {
      'ad_type': 'rewarded',
      'source': source,
    });

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastRewardedShow = DateTime.now();
        
        FirebaseManager().logEvent('ad_shown', parameters: {
          'ad_type': 'rewarded',
          'source': source,
        });
      },
      onAdDismissedFullScreenContent: (ad) {
        _rewardedAd?.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
        
        // Preload next rewarded ad
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _rewardedAd?.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
        onRewardFailed?.call();
        
        FirebaseManager().logEvent('ad_show_failed', parameters: {
          'ad_type': 'rewarded',
          'error_code': error.code,
          'error_message': error.message,
        });
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      FirebaseManager().logEvent('ad_reward_earned', parameters: {
        'ad_type': 'rewarded',
        'source': source,
        'reward_type': reward.type,
        'reward_amount': reward.amount,
      });
      
      onReward(reward);
    });

    return true;
  }

  /// Check if ads should be hidden (premium users)
  bool _shouldHideAds() {
    return FirebaseManager().isPremium;
  }

  /// Check if interstitial can be shown (frequency capping)
  bool _canShowInterstitial() {
    // Respect cooldown period
    if (_lastInterstitialShow != null &&
        DateTime.now().difference(_lastInterstitialShow!) < _interstitialCooldown) {
      return false;
    }

    // Respect session limit
    if (_interstitialShowCount >= _maxInterstitialsPerSession) {
      return false;
    }

    return true;
  }

  /// Check if rewarded ad can be shown
  bool _canShowRewarded() {
    if (_lastRewardedShow != null &&
        DateTime.now().difference(_lastRewardedShow!) < _rewardedCooldown) {
      return false;
    }
    return true;
  }

  /// Get ad availability status
  Map<String, bool> getAdAvailability() {
    return {
      'banner': _isBannerLoaded && !_shouldHideAds(),
      'interstitial': _isInterstitialReady && !_shouldHideAds() && _canShowInterstitial(),
      'rewarded': _isRewardedReady && _canShowRewarded(),
    };
  }

  /// Refresh ads (call when coming back from background)
  Future<void> refreshAds() async {
    if (!_adsEnabled) return;

    // Reload ads that aren't ready
    if (!_isBannerLoaded) await _loadBannerAd();
    if (!_isInterstitialReady) await _loadInterstitialAd();
    if (!_isRewardedReady) await _loadRewardedAd();
  }

  /// Show contextual premium upgrade prompt
  Future<void> showUpgradePrompt(String feature, String source) async {
    await FirebaseManager().logUpgradeClick(source, PremiumTier.pro);
    
    // This would show a custom dialog with upgrade options
    // Implementation depends on your premium system
  }

  /// Dispose all ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    
    _isBannerLoaded = false;
    _isInterstitialReady = false;
    _isRewardedReady = false;
  }

  /// Reset session counters (call on app restart)
  void resetSession() {
    _sessionCount++;
    _interstitialShowCount = 0;
    _lastInterstitialShow = null;
    _lastRewardedShow = null;
  }

  /// Enable/disable ads (for premium users)
  void setAdsEnabled(bool enabled) {
    _adsEnabled = enabled;
    
    if (!enabled) {
      // Dispose ads immediately for premium users
      _bannerAd?.dispose();
      _bannerAd = null;
      _isBannerLoaded = false;
    } else {
      // Re-enable ads for free users
      _loadAllAds();
    }
  }

  /// Get performance metrics for optimization
  Map<String, dynamic> getMetrics() {
    return {
      'session_count': _sessionCount,
      'interstitial_shows': _interstitialShowCount,
      'ads_enabled': _adsEnabled,
      'is_premium': _shouldHideAds(),
      'banner_loaded': _isBannerLoaded,
      'interstitial_ready': _isInterstitialReady,
      'rewarded_ready': _isRewardedReady,
    };
  }
}

/// Ad placement strategies for different app contexts
enum AdPlacement {
  mainScreen,     // Banner at bottom
  sessionBreak,   // Interstitial after certain time
  presetSave,     // Interstitial when saving preset
  featureGate,    // Rewarded for temporary premium access
  appLaunch,      // Occasional interstitial on cold start
  sharing,        // Interstitial before sharing
}

/// Extension for ad placement configuration
extension AdPlacementConfig on AdPlacement {
  String get source {
    switch (this) {
      case AdPlacement.mainScreen:
        return 'main_screen';
      case AdPlacement.sessionBreak:
        return 'session_break';
      case AdPlacement.presetSave:
        return 'preset_save';
      case AdPlacement.featureGate:
        return 'feature_gate';
      case AdPlacement.appLaunch:
        return 'app_launch';
      case AdPlacement.sharing:
        return 'sharing';
    }
  }

  bool get isInterstitial {
    switch (this) {
      case AdPlacement.sessionBreak:
      case AdPlacement.presetSave:
      case AdPlacement.appLaunch:
      case AdPlacement.sharing:
        return true;
      default:
        return false;
    }
  }

  bool get isRewarded {
    return this == AdPlacement.featureGate;
  }
}