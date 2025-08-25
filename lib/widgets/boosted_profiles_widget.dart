import 'package:flutter/material.dart';
import 'dart:async';
import '../services/boost_profile_service.dart';

class BoostedProfilesWidget extends StatefulWidget {
  const BoostedProfilesWidget({super.key});

  @override
  State<BoostedProfilesWidget> createState() => BoostedProfilesWidgetState();
}

class BoostedProfilesWidgetState extends State<BoostedProfilesWidget>
    with TickerProviderStateMixin {
  final BoostProfileService _boostService = BoostProfileService();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Map<String, dynamic>> _boostedProfiles = [];
  bool _isLoading = true;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadBoostedProfiles();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(BoostedProfilesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh boosted profiles when widget is updated
    _loadBoostedProfiles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBoostedProfiles() async {
    try {
      final profiles = await _boostService.getBoostedProfiles();
      
      setState(() {
        _boostedProfiles = profiles;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Public method to refresh boosted profiles
  Future<void> refreshBoostedProfiles() async {
    setState(() {
      _isLoading = true;
    });
    await _loadBoostedProfiles();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_scrollController.hasClients && _boostedProfiles.isNotEmpty) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        
        if (currentScroll >= maxScroll) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        } else {
          _scrollController.animateTo(
            currentScroll + 150,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.withOpacity(0.15),
              Colors.orange.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
        ),
      );
    }

    if (_boostedProfiles.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.withOpacity(0.2),
              Colors.orange.withOpacity(0.15),
            ],
          ),
          border: Border.all(
            color: Colors.amber.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.star_outline,
                color: Colors.amber.shade700,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No boosted profiles yet',
              style: TextStyle(
                color: Colors.amber.shade700,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Boost your profile to appear in the spotlight!',
              style: TextStyle(
                color: Colors.amber.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.withOpacity(0.2),
              Colors.orange.withOpacity(0.15),
            ],
          ),
          border: Border.all(
            color: Colors.amber.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withOpacity(0.3),
                    Colors.orange.withOpacity(0.2),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Popular Profiles',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Trending boosted profiles',
                          style: TextStyle(
                            color: Colors.amber.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_boostedProfiles.length} active',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => refreshBoostedProfiles(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: Colors.amber.shade700,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Table content
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _boostedProfiles.length,
                  itemBuilder: (context, index) {
                    final profile = _boostedProfiles[index];
                    return _buildTableRow(profile, index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> profile, int index) {
    final displayName = profile['displayName'] ?? profile['username'] ?? 'Unknown';
    final profilePicture = profile['profilePicture'] as String?;
    final age = profile['age']?.toString() ?? '';
    final location = profile['location'] ?? '';
    final interests = (profile['interests'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.15),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank number with gold styling
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade400,
                    Colors.orange.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Profile picture with gold border
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.shade400,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: profilePicture != null && profilePicture.isNotEmpty
                    ? Image.network(
                        profilePicture,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.person,
                              color: Colors.grey.shade600,
                              size: 24,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.person,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (age.isNotEmpty || location.isNotEmpty)
                    Text(
                      [age, location].where((s) => s.isNotEmpty).join(' • '),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (interests.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      interests.take(2).join(', '),
                      style: TextStyle(
                        color: Colors.amber.withOpacity(0.9),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Boost indicator with gold styling
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade400,
                    Colors.orange.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
