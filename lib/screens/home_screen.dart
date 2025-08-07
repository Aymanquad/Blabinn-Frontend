import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bg1.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Woman image
            _buildWomanImage(),
            const SizedBox(height: 24),
            
            // Text and button
            _buildConnectSection(),
            
            const Spacer(),
            
            // Banner Ad at the bottom
            const BannerAdWidget(
              height: 50,
              margin: EdgeInsets.only(bottom: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWomanImage() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      child: Center(
        child: Image.asset(
          'assets/images/Girl-image.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildConnectSection() {
    return Column(
      children: [
        const Text(
          'Ready to meet new people ?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        
        // Connect Now button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              widget.onNavigateToTab?.call(2); // Navigate to Connect tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6), // Purple gradient
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
            child: const Text(
              'Connect Now',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Text(
          'Find and chat with people around the world',
          style: TextStyle(
            color: Colors.purple[200],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
