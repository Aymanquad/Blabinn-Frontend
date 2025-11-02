import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../core/constants.dart';
import '../widgets/consistent_app_bar.dart';

class TestInterstitialScreen extends StatefulWidget {
  const TestInterstitialScreen({super.key});

  @override
  State<TestInterstitialScreen> createState() => _TestInterstitialScreenState();
}

class _TestInterstitialScreenState extends State<TestInterstitialScreen> {
  final AdService _adService = AdService();
  bool _isAdLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAds();
  }

  Future<void> _initializeAds() async {
    setState(() {
      _statusMessage = 'Initializing ads...';
    });

    try {
      await _adService.initialize();
      setState(() {
        _statusMessage = 'Ads initialized successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to initialize ads: $e';
      });
    }
  }

  Future<void> _loadInterstitialAd() async {
    setState(() {
      _isAdLoading = true;
      _statusMessage = 'Loading interstitial ad...';
    });

    try {
      await _adService.loadInterstitialAd();
      setState(() {
        _isAdLoading = false;
        _statusMessage = 'Interstitial ad loaded successfully!';
      });
    } catch (e) {
      setState(() {
        _isAdLoading = false;
        _statusMessage = 'Failed to load interstitial ad: $e';
      });
    }
  }

  Future<void> _showInterstitialAd() async {
    setState(() {
      _statusMessage = 'Showing interstitial ad...';
    });

    try {
      await _adService.showInterstitialAd();
      setState(() {
        _statusMessage = 'Interstitial ad shown!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to show interstitial ad: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Interstitial Ad Test',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Interstitial Ad Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: $_statusMessage',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isAdLoading ? null : _loadInterstitialAd,
              child: _isAdLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading...'),
                      ],
                    )
                  : const Text('Load Interstitial Ad'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showInterstitialAd,
              child: const Text('Show Interstitial Ad'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _adService.resumeInterstitialTimer();
                setState(() {
                  _statusMessage = 'Timer resumed!';
                });
              },
              child: const Text('Resume Timer'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _adService.pauseInterstitialTimer();
                setState(() {
                  _statusMessage = 'Timer paused!';
                });
              },
              child: const Text('Pause Timer'),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• The app automatically shows interstitial ads every 20 seconds\n'
                      '• Use the buttons above to test manual ad loading and showing\n'
                      '• Timer controls allow you to pause/resume the automatic ads\n'
                      '• Check the console for detailed ad status messages',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 