import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/chatify_ad_service.dart';
import '../core/theme_extensions.dart';

/// Chatify Banner Ad Widget
/// Displays banner ads with proper integration to Chatify ad service
class ChatifyBannerAd extends StatefulWidget {
  final String? adUnitId;
  final AdSize adSize;
  final EdgeInsets? margin;
  final bool showBorder;

  const ChatifyBannerAd({
    Key? key,
    this.adUnitId,
    this.adSize = AdSize.banner,
    this.margin,
    this.showBorder = false,
  }) : super(key: key);

  @override
  State<ChatifyBannerAd> createState() => _ChatifyBannerAdState();
}

class _ChatifyBannerAdState extends State<ChatifyBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final ChatifyAdService _adService = ChatifyAdService();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = _adService.createBannerAd();
    
    _bannerAd!.load().then((_) {
      if (mounted) {
        setState(() {
          _isAdLoaded = true;
        });
      }
    }).catchError((error) {
      print('Failed to load banner ad: $error');
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    // Don't show ad if not loaded or if user shouldn't see ads
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(8.0),
      decoration: widget.showBorder
          ? BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(tokens.radiusS),
            )
          : null,
      child: ClipRRect(
        borderRadius: widget.showBorder
            ? BorderRadius.circular(tokens.radiusS)
            : BorderRadius.zero,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}

/// Compact Banner Ad for smaller spaces
class CompactBannerAd extends StatelessWidget {
  final EdgeInsets? margin;

  const CompactBannerAd({
    Key? key,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChatifyBannerAd(
      adSize: AdSize.mediumRectangle,
      margin: margin,
      showBorder: true,
    );
  }
}

/// Large Banner Ad for prominent placement
class LargeBannerAd extends StatelessWidget {
  final EdgeInsets? margin;

  const LargeBannerAd({
    Key? key,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChatifyBannerAd(
      adSize: AdSize.largeBanner,
      margin: margin,
      showBorder: true,
    );
  }
}

/// Adaptive Banner Ad that adjusts to screen width
class AdaptiveBannerAd extends StatefulWidget {
  final EdgeInsets? margin;
  final bool showBorder;

  const AdaptiveBannerAd({
    Key? key,
    this.margin,
    this.showBorder = true,
  }) : super(key: key);

  @override
  State<AdaptiveBannerAd> createState() => _AdaptiveBannerAdState();
}

class _AdaptiveBannerAdState extends State<AdaptiveBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final ChatifyAdService _adService = ChatifyAdService();

  @override
  void initState() {
    super.initState();
    _loadAdaptiveBannerAd();
  }

  void _loadAdaptiveBannerAd() async {
    final adSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    );

    if (adSize == null) {
      print('Failed to get adaptive banner ad size');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: _adService.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load adaptive banner ad: ${error.message}');
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(8.0),
      decoration: widget.showBorder
          ? BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(tokens.radiusS),
            )
          : null,
      child: ClipRRect(
        borderRadius: widget.showBorder
            ? BorderRadius.circular(tokens.radiusS)
            : BorderRadius.zero,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
