import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final double? height;
  final EdgeInsets? margin;
  final bool showLoadingIndicator;

  const BannerAdWidget({
    super.key,
    this.height,
    this.margin,
    this.showLoadingIndicator = true,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adService = AdService();
      final bannerAd = await adService.loadBannerAd();
      
      if (mounted && bannerAd != null) {
        setState(() {
          _bannerAd = bannerAd;
          _isLoaded = true;
          _isLoading = false;
        });
        debugPrint('✅ Banner ad loaded successfully in widget');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load ad';
        });
        debugPrint('❌ Banner ad failed to load in widget');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading ad: ${e.toString()}';
        });
      }
      debugPrint('❌ Error loading banner ad in widget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator
    if (_isLoading && widget.showLoadingIndicator) {
      return Container(
        height: widget.height ?? 50,
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Container(
        height: widget.height ?? 50,
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Center(
          child: Text(
            'Ad not available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // Show ad if loaded
    if (_isLoaded && _bannerAd != null) {
      return Container(
        height: widget.height ?? 50,
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Hide widget if no ad loaded and no error
    return const SizedBox.shrink();
  }
} 