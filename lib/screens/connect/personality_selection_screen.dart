import 'package:flutter/material.dart';

class PersonalitySelectionScreen extends StatefulWidget {
  final void Function(Map<String, dynamic>) onPersonalitySelected;
  final VoidCallback? onBack;

  const PersonalitySelectionScreen({
    super.key,
    required this.onPersonalitySelected,
    this.onBack,
  });

  @override
  State<PersonalitySelectionScreen> createState() =>
      _PersonalitySelectionScreenState();
}

class _PersonalitySelectionScreenState extends State<PersonalitySelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedPersonalityId;

  // AI Personality Types
  final List<Map<String, dynamic>> _personalities = [
    {
      'id': 'flirty-romantic',
      'name': '💕 Flirty & Romantic',
      'type': 'Flirty',
      'bio': 'Charming, playful, and loves romantic conversations 😘',
      'interests': ['romance', 'dating', 'compliments', 'sweet talk'],
      'icon': Icons.favorite,
      'color': Colors.pink,
      'description': 'Flirty and charming - perfect for romantic chats',
      'traits': ['Charming', 'Playful', 'Romantic', 'Sweet']
    },
    {
      'id': 'energetic-fun',
      'name': '⚡ Energetic & Fun',
      'type': 'Energetic',
      'bio': 'High energy, loves adventures and making people laugh! 🎉',
      'interests': ['adventure', 'comedy', 'parties', 'excitement'],
      'icon': Icons.bolt,
      'color': Colors.orange,
      'description':
          'Super energetic and fun - brings excitement to every chat',
      'traits': ['Energetic', 'Fun', 'Adventurous', 'Exciting']
    },
    {
      'id': 'anime-kawaii',
      'name': '🌸 Anime & Kawaii',
      'type': 'Anime-like',
      'bio': 'Kawaii desu! Loves anime, manga, and being cute~ (◕‿◕)♡',
      'interests': ['anime', 'manga', 'kawaii culture', 'cosplay'],
      'icon': Icons.auto_awesome,
      'color': Colors.purple,
      'description': 'Cute anime personality - kawaii and adorable',
      'traits': ['Kawaii', 'Cute', 'Anime Fan', 'Sweet']
    },
    {
      'id': 'mysterious-dark',
      'name': '🌙 Mysterious & Dark',
      'type': 'Mysterious',
      'bio': 'Enigmatic soul with deep thoughts and mysterious charm... 🖤',
      'interests': ['mystery', 'philosophy', 'dark aesthetics', 'secrets'],
      'icon': Icons.nightlight,
      'color': Colors.indigo,
      'description': 'Dark and mysterious - intriguing conversations await',
      'traits': ['Mysterious', 'Deep', 'Enigmatic', 'Thoughtful']
    },
    {
      'id': 'supportive-caring',
      'name': '🤗 Supportive & Caring',
      'type': 'Supportive',
      'bio': 'Always here to listen, support, and make you feel better 💚',
      'interests': ['listening', 'helping', 'emotional support', 'kindness'],
      'icon': Icons.healing,
      'color': Colors.green,
      'description': 'Caring and supportive - your emotional companion',
      'traits': ['Caring', 'Supportive', 'Kind', 'Understanding']
    },
    {
      'id': 'sassy-confident',
      'name': '💅 Sassy & Confident',
      'type': 'Sassy',
      'bio': 'Confident, witty, and not afraid to speak my mind! 💁‍♀️✨',
      'interests': ['confidence', 'wit', 'fashion', 'attitude'],
      'icon': Icons.star,
      'color': Colors.amber,
      'description': 'Sassy and confident - bold conversations guaranteed',
      'traits': ['Confident', 'Sassy', 'Witty', 'Bold']
    }
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectPersonality(Map<String, dynamic> personality) {
    setState(() {
      _selectedPersonalityId = personality['id'] as String;
    });

    // Add haptic feedback
    // HapticFeedback.lightImpact();

    // Wait a moment for visual feedback, then proceed
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onPersonalitySelected(personality);
    });
  }

  @override
  Widget build(BuildContext context) {
    // final tokens = Theme.of(context).extension<AppThemeTokens>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f0f23),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Personalities List
                  Expanded(
                    child: _buildPersonalitiesList(),
                  ),

                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Back button row
          Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.3)
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Text(
              '🤖 AI MATCH FOUND!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Choose Your Personality Type',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Pick the personality that matches your mood 💫',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitiesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _personalities.length,
      itemBuilder: (context, index) {
        final personality = _personalities[index];
        final isSelected = _selectedPersonalityId == personality['id'];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildPersonalityCard(personality, isSelected),
        );
      },
    );
  }

  Widget _buildPersonalityCard(
      Map<String, dynamic> personality, bool isSelected) {
    final color = personality['color'] as Color;
    final interests = personality['interests'] as List<String>;

    return GestureDetector(
      onTap: () => _selectPersonality(personality),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.04),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon and selection indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    personality['icon'] as IconData,
                    color: color,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personality['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        personality['type'] as String,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? color
                          : Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              personality['description'] as String,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            // Bio
            Text(
              '"${personality['bio']}"',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Personality Traits
            Text(
              'Personality Traits:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (personality['traits'] as List<String>)
                  .map((trait) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.3),
                              color.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          trait,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // Interests
            Text(
              'Interests:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 6),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: interests
                  .map((interest) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Tap any personality type to start your AI chat',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Random selection button
          TextButton(
            onPressed: () {
              // Select random personality
              final randomPersonality = _personalities[
                  DateTime.now().millisecond % _personalities.length];
              _selectPersonality(randomPersonality);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shuffle,
                    color: Colors.white.withValues(alpha: 0.8), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Surprise Me!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
