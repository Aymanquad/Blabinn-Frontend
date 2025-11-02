import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:io';
import 'dart:async';
import '../core/ad_config.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// Chatify Ad Service
/// Implements the specific ad placement strategy for Chatify
class ChatifyAdService {
  static final ChatifyAdService _instance = ChatifyAdService._internal();
  factory ChatifyAdService() => _instance;
  ChatifyAdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  Timer? _interstitialTimer;
  bool _isInterstitialAdLoading = false;
  bool _isInterstitialAdShowing = false;
  bool _isRewardedAdLoading = false;
  bool _isRewardedAdShowing = false;

  // Ad tracking counters
  int _connectCount = 0;
  int _pageSwitchCount = 0;
  DateTime? _lastPageSwitchTime;
  int _dailyAdViews = 0;
  DateTime? _lastAdViewDate;
  int _whoLikedViews = 0;
  DateTime? _lastWhoLikedViewDate;

  // User reference
  User? _currentUser;
  final ApiService _apiService = ApiService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Initialize the Chatify Ad Service
  Future<void> initialize(User? user) async {
    _currentUser = user;

    if (_isInitialized) return;

    // Check if ads are enabled and user should see ads
    if (!_shouldShowAds()) {
      _isInitialized = true;
      return;
    }

    try {
      // Initialize Mobile Ads with proper configuration
      final initializationStatus = await MobileAds.instance.initialize();

      // Log initialization status
      for (final adapterStatus
          in initializationStatus.adapterStatuses.entries) {
        final name = adapterStatus.key;
        final status = adapterStatus.value;
        print('🔧 Adapter $name: ${status.description}');
      }

      _isInitialized = true;

      // Load initial ads
      await _loadInterstitialAd();
      await _loadRewardedAd();

      // Reset daily counters if needed
      _resetDailyCountersIfNeeded();

      print('✅ Chatify Ad Service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Chatify Ad Service: $e');
    }
  }

  /// Check if user should see ads
  bool _shouldShowAds() {
    if (!AdConfig.adsEnabled) return false;
    if (_currentUser == null) return true; // Show ads for unauthenticated users

    // Premium users with ads-free don't see ads
    if (_currentUser!.isPremiumUser && _currentUser!.adsFree) return false;

    // Women get all features free but still see ads (special rule)
    return true;
  }

  /// Get the appropriate Rewarded Ad Unit ID based on platform
  String get rewardedAdUnitId {
    if (Platform.isIOS) {
      return AdConfig.iosRewardedAdUnitId;
    }
    return AdConfig.androidRewardedAdUnitId;
  }

  /// Get the appropriate Interstitial Ad Unit ID based on platform
  String get interstitialAdUnitId {
    if (Platform.isIOS) {
      return AdConfig.iosInterstitialAdUnitId;
    }
    return AdConfig.androidInterstitialAdUnitId;
  }

  /// Get the appropriate Banner Ad Unit ID based on platform
  String get bannerAdUnitId {
    if (Platform.isIOS) {
      return AdConfig.iosBannerAdUnitId;
    }
    return AdConfig.androidBannerAdUnitId;
  }

  // ==================== BANNER ADS (Persistent Everywhere) ====================

  /// Create a banner ad for persistent display
  BannerAd createBannerAd() {
    if (!_shouldShowAds()) {
      return BannerAd(
        adUnitId: 'dummy-id',
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdFailedToLoad: (ad, error) => ad.dispose(),
        ),
      );
    }

    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('✅ Banner ad loaded'),
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner ad failed to load: ${error.message}');
          ad.dispose();
        },
        onAdOpened: (ad) => print('🔓 Banner ad opened'),
        onAdClosed: (ad) => print('🔒 Banner ad closed'),
      ),
    );
  }

  // ==================== INTERSTITIAL ADS (Specific Triggers) ====================

  /// Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (!_shouldShowAds() ||
        _isInterstitialAdLoading ||
        _interstitialAd != null) {
      return;
    }

    _isInterstitialAdLoading = true;

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoading = false;
            print('✅ Interstitial ad loaded successfully');

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('🔒 Interstitial ad dismissed');
                _interstitialAd = null;
                _isInterstitialAdShowing = false;
                _loadInterstitialAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('❌ Interstitial ad failed to show: ${error.message}');
                _interstitialAd = null;
                _isInterstitialAdShowing = false;
                _loadInterstitialAd(); // Load next ad
              },
              onAdShowedFullScreenContent: (ad) {
                print('🔓 Interstitial ad showed');
                _isInterstitialAdShowing = true;
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('❌ Interstitial ad failed to load: ${error.message}');
            _isInterstitialAdLoading = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      print('❌ Failed to load interstitial ad: $e');
      _isInterstitialAdLoading = false;
    }
  }

  /// Show interstitial ad if available
  Future<void> showInterstitialAd() async {
    if (!_shouldShowAds() ||
        _interstitialAd == null ||
        _isInterstitialAdShowing) {
      return;
    }

    try {
      await _interstitialAd!.show();
      print('🎬 Showing interstitial ad');
    } catch (e) {
      print('❌ Failed to show interstitial ad: $e');
      _interstitialAd = null;
      _isInterstitialAdShowing = false;
    }
  }

  // ==================== INTERSTITIAL AD TRIGGERS ====================

  /// Trigger: Before match when clicking Connect
  Future<void> onConnectClick() async {
    if (!_shouldShowAds()) return;

    _connectCount++;
    await _updateConnectCount();

    // Show interstitial before match
    await showInterstitialAd();
  }

  /// Trigger: After every 2 Connects
  Future<void> onConnectComplete() async {
    if (!_shouldShowAds()) return;

    if (_connectCount % 2 == 0) {
      await showInterstitialAd();
    }
  }

  /// Trigger: After switching pages 3 times
  Future<void> onPageSwitch() async {
    if (!_shouldShowAds()) return;

    final now = DateTime.now();

    // Reset counter if more than 1 hour has passed
    if (_lastPageSwitchTime != null &&
        now.difference(_lastPageSwitchTime!).inHours >= 1) {
      _pageSwitchCount = 0;
    }

    _pageSwitchCount++;
    _lastPageSwitchTime = now;
    await _updatePageSwitchCount();

    if (_pageSwitchCount % 3 == 0) {
      await showInterstitialAd();
    }
  }

  /// Trigger: On entering Credit Shop
  Future<void> onEnterCreditShop() async {
    if (!_shouldShowAds()) return;
    await showInterstitialAd();
  }

  // ==================== POP-UP ADS ====================

  /// Trigger: After every Connect
  Future<void> onConnectCompletePopUp() async {
    if (!_shouldShowAds()) return;

    // Show pop-up ad after connect
    _showPopUpAd('Great connection! Check out our premium features!');
  }

  /// Trigger: When clicking on profile
  Future<void> onProfileClick() async {
    if (!_shouldShowAds()) return;

    // Show pop-up ad when viewing profile
    _showPopUpAd('Upgrade to Premium for unlimited profile views!');
  }

  /// Show pop-up ad (using dialog for now, can be replaced with actual pop-up ad)
  void _showPopUpAd(String message) {
    // This would be replaced with actual pop-up ad implementation
    print('📢 Pop-up Ad: $message');
  }

  // ==================== REWARDED ADS ====================

  /// Load rewarded ad
  Future<void> _loadRewardedAd() async {
    print('🎯 _loadRewardedAd: Starting...');
    print('🎯 _loadRewardedAd: _shouldShowAds() = ${_shouldShowAds()}');
    print('🎯 _loadRewardedAd: _isRewardedAdLoading = $_isRewardedAdLoading');
    print('🎯 _loadRewardedAd: _rewardedAd != null = ${_rewardedAd != null}');
    print('🎯 _loadRewardedAd: rewardedAdUnitId = $rewardedAdUnitId');

    if (!_shouldShowAds() || _isRewardedAdLoading || _rewardedAd != null) {
      print('🎯 _loadRewardedAd: Skipping load (conditions not met)');
      return;
    }

    _isRewardedAdLoading = true;
    print('🎯 _loadRewardedAd: Loading ad...');

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(
          keywords: <String>['social', 'chat', 'dating'],
          nonPersonalizedAds: true,
        ),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isRewardedAdLoading = false;
            print('✅ Rewarded ad loaded successfully');

            // Log ad loaded event to Firebase Analytics
            _analytics.logEvent(
              name: 'rewarded_ad_loaded',
              parameters: {
                'ad_unit_id': rewardedAdUnitId,
                'user_type':
                    _currentUser?.isPremium == true ? 'premium' : 'free',
              },
            );

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('🔒 Rewarded ad dismissed');
                _rewardedAd = null;
                _isRewardedAdShowing = false;
                _loadRewardedAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('❌ Rewarded ad failed to show: ${error.message}');
                _rewardedAd = null;
                _isRewardedAdShowing = false;
                _loadRewardedAd(); // Load next ad
              },
              onAdShowedFullScreenContent: (ad) {
                print('🔓 Rewarded ad showed');
                _isRewardedAdShowing = true;

                // Log ad shown event to Firebase Analytics
                _analytics.logEvent(
                  name: 'rewarded_ad_shown',
                  parameters: {
                    'ad_unit_id': rewardedAdUnitId,
                    'user_type':
                        _currentUser?.isPremium == true ? 'premium' : 'free',
                  },
                );
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('❌ Rewarded ad failed to load: ${error.message}');
            print('❌ Error code: ${error.code}');
            print('❌ Error domain: ${error.domain}');
            _isRewardedAdLoading = false;
            _rewardedAd = null;

            // Log ad load failure to Firebase Analytics
            _analytics.logEvent(
              name: 'rewarded_ad_load_failed',
              parameters: {
                'error_code': error.code,
                'error_domain': error.domain,
                'error_message': error.message,
                'ad_unit_id': rewardedAdUnitId,
              },
            );

            // Retry loading with shorter initial delay
            Timer(const Duration(seconds: 5), () {
              if (_shouldShowAds() &&
                  _rewardedAd == null &&
                  !_isRewardedAdLoading) {
                print('🔄 Retrying rewarded ad load immediately...');
                _loadRewardedAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      print('❌ Failed to load rewarded ad: $e');
      _isRewardedAdLoading = false;

      // Log exception to Firebase Analytics
      _analytics.logEvent(
        name: 'rewarded_ad_load_exception',
        parameters: {
          'exception': e.toString(),
          'ad_unit_id': rewardedAdUnitId,
        },
      );
    }
  }

  /// Show rewarded ad
  Future<bool> showRewardedAd() async {
    print('🎯 showRewardedAd: Starting...');
    print('🎯 showRewardedAd: _shouldShowAds() = ${_shouldShowAds()}');
    print('🎯 showRewardedAd: _rewardedAd != null = ${_rewardedAd != null}');
    print('🎯 showRewardedAd: _isRewardedAdShowing = $_isRewardedAdShowing');
    print('🎯 showRewardedAd: _isRewardedAdLoading = $_isRewardedAdLoading');

    if (!_shouldShowAds()) {
      print('❌ showRewardedAd: Ads disabled or user is premium');
      return false;
    }

    if (_rewardedAd == null) {
      print('❌ showRewardedAd: No rewarded ad loaded');
      // Try to load a new ad
      await _loadRewardedAd();
      if (_rewardedAd == null) {
        print('❌ showRewardedAd: Failed to load rewarded ad');
        return false;
      }
    }

    if (_isRewardedAdShowing) {
      print('❌ showRewardedAd: Ad already showing');
      return false;
    }

    try {
      print('🎯 showRewardedAd: Showing ad...');
      await _rewardedAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        print('🎁 User earned reward: ${reward.amount} ${reward.type}');

        try {
          await _onRewardEarned(reward);
          print('✅ Reward processed successfully');
        } catch (e) {
          print('❌ Failed to process reward: $e');
        }

        // Log reward earned event to Firebase Analytics
        _analytics.logEvent(
          name: 'reward_earned',
          parameters: {
            'reward_amount': reward.amount,
            'reward_type': reward.type,
            'ad_unit_id': rewardedAdUnitId,
            'user_type': _currentUser?.isPremium == true ? 'premium' : 'free',
          },
        );

        _onRewardEarned(reward);
      });
      print('✅ showRewardedAd: Ad shown successfully');
      return true;
    } catch (e) {
      print('❌ Failed to show rewarded ad: $e');

      // Log show failure to Firebase Analytics
      _analytics.logEvent(
        name: 'rewarded_ad_show_failed',
        parameters: {
          'exception': e.toString(),
          'ad_unit_id': rewardedAdUnitId,
        },
      );

      _rewardedAd = null;
      _isRewardedAdShowing = false;
      return false;
    }
  }

  /// Handle reward earned
  Future<void> _onRewardEarned(RewardItem reward) async {
    try {
      _dailyAdViews++;
      _lastAdViewDate = DateTime.now();
      await _updateDailyAdViews();

      // Grant credits through API
      final result = await _apiService.grantAdCredits(
          amount: reward.amount.toInt(), trigger: 'credit_shop_reward');

      // Update user's credits in provider
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
            credits: (result['credits'] as int?) ?? _currentUser!.credits);
      }
    } catch (e) {
      print('❌ Failed to process reward: $e');
      rethrow;
    }
  }

  // ==================== REWARDED AD TRIGGERS ====================

  /// Trigger: Accepting friend request → unlocks via reward ad
  Future<bool> onAcceptFriendRequest() async {
    if (!_shouldShowAds()) return true; // Allow without ad for premium users

    final success = await showRewardedAd();
    if (success) {
      print('✅ Friend request accepted via reward ad');
    }
    return success;
  }

  /// Trigger: Collecting daily bonus → 2 reward ads
  Future<bool> onCollectDailyBonus() async {
    if (!_shouldShowAds()) return true; // Allow without ad for premium users

    // Show 2 reward ads for daily bonus
    bool success1 = await showRewardedAd();
    if (success1) {
      // Wait a bit before showing second ad
      await Future.delayed(const Duration(seconds: 2));
      bool success2 = await showRewardedAd();
      return success1 && success2;
    }
    return false;
  }

  /// Trigger: Gender filter → watch 3 reward ads = filter unlock for 5 mins
  Future<bool> onGenderFilterUnlock() async {
    if (!_shouldShowAds()) return true; // Allow without ad for premium users

    // Show 3 reward ads for gender filter unlock
    bool success1 = await showRewardedAd();
    if (success1) {
      await Future.delayed(const Duration(seconds: 2));
      bool success2 = await showRewardedAd();
      if (success2) {
        await Future.delayed(const Duration(seconds: 2));
        bool success3 = await showRewardedAd();
        if (success3) {
          // Unlock gender filter for 5 minutes
          _unlockGenderFilter();
          return true;
        }
      }
    }
    return false;
  }

  /// Trigger: Viewing who liked you → watch reward ads (max 3 views/day if no plan)
  Future<bool> onViewWhoLikedYou() async {
    if (!_shouldShowAds()) return true; // Allow without ad for premium users

    // Check daily limit
    if (_whoLikedViews >= 3) {
      print('❌ Daily limit reached for "Who Liked You" views');
      return false;
    }

    final success = await showRewardedAd();
    if (success) {
      _whoLikedViews++;
      _lastWhoLikedViewDate = DateTime.now();
      _updateWhoLikedViews();
      print('✅ "Who Liked You" view unlocked via reward ad');
    }
    return success;
  }

  // ==================== HELPER METHODS ====================

  /// Reset daily counters if needed
  void _resetDailyCountersIfNeeded() {
    final now = DateTime.now();

    // Reset daily ad views
    if (_lastAdViewDate == null ||
        now.difference(_lastAdViewDate!).inDays >= 1) {
      _dailyAdViews = 0;
      _lastAdViewDate = now;
    }

    // Reset who liked views
    if (_lastWhoLikedViewDate == null ||
        now.difference(_lastWhoLikedViewDate!).inDays >= 1) {
      _whoLikedViews = 0;
      _lastWhoLikedViewDate = now;
    }
  }

  /// Unlock gender filter for 5 minutes
  void _unlockGenderFilter() {
    // This would integrate with your filter system
    print('🔓 Gender filter unlocked for 5 minutes');
    // Set a timer to lock it again after 5 minutes
    Timer(const Duration(minutes: 5), () {
      print('🔒 Gender filter locked again');
    });
  }

  /// Update connect count in backend
  Future<void> _updateConnectCount() async {
    if (_currentUser == null) return;

    try {
      // Use dedicated ad-tracking endpoint
      await _apiService.updateConnectCount(_connectCount);
    } catch (e) {
      print('❌ Failed to update connect count: $e');
    }
  }

  /// Update page switch count in backend
  Future<void> _updatePageSwitchCount() async {
    if (_currentUser == null) return;

    try {
      // Provide last switch time as required by API
      await _apiService.updatePageSwitchCount(
        _pageSwitchCount,
        _lastPageSwitchTime ?? DateTime.now(),
      );
    } catch (e) {
      print('❌ Failed to update page switch count: $e');
    }
  }

  /// Update daily ad views in backend
  Future<void> _updateDailyAdViews() async {
    if (_currentUser == null) return;

    try {
      await _apiService.updateDailyAdViews(
        _dailyAdViews,
        _lastAdViewDate ?? DateTime.now(),
      );
    } catch (e) {
      print('❌ Failed to update daily ad views: $e');
    }
  }

  /// Update who liked views in backend
  Future<void> _updateWhoLikedViews() async {
    if (_currentUser == null) return;

    try {
      await _apiService.updateWhoLikedViews(
        _whoLikedViews,
        _lastWhoLikedViewDate ?? DateTime.now(),
      );
    } catch (e) {
      print('❌ Failed to update who liked views: $e');
    }
  }

  /// Update user reference
  void updateUser(User? user) {
    _currentUser = user;
    _resetDailyCountersIfNeeded();
  }

  /// Get current ad statistics
  Map<String, dynamic> getAdStats() {
    return {
      'connectCount': _connectCount,
      'pageSwitchCount': _pageSwitchCount,
      'dailyAdViews': _dailyAdViews,
      'whoLikedViews': _whoLikedViews,
      'shouldShowAds': _shouldShowAds(),
    };
  }

  /// Dispose of all ads and timers
  void dispose() {
    _interstitialTimer?.cancel();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    print('🗑️ Chatify Ad Service disposed');
  }
}
