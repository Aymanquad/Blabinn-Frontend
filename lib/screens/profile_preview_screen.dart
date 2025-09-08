import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/user.dart' as model;
import '../services/api_service.dart';
import '../services/matching_service.dart';
import '../widgets/profile_preview_card.dart';

class ProfilePreviewScreen extends StatefulWidget {
  final String? userId; // null => show current user's preview
  final Map<String, dynamic>? initialUserData;

  const ProfilePreviewScreen({super.key, this.userId, this.initialUserData});

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  final ApiService _api = ApiService();
  final MatchingService _matching = MatchingService();

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.initialize();
      if (widget.initialUserData != null) {
        _data = widget.initialUserData;
      } else if (widget.userId != null) {
        _data = await _api.getUserProfile(widget.userId!);
      } else {
        final me = await _api.getMyProfile();
        _data = me['profile'] ?? me;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleLike() async {
    if (_data == null) return;
    try {
      final id = _data!['uid'] ?? _data!['id'];
      if (id == null) return;
      // Use connection flow instead of non-existent matching route
      await _api.postJson('/connections/friend-request', {'toUserId': id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent')), 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Preview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/violettoblack_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
              child: ProfilePreviewCard(
                imageUrl: _data!['profilePicture'] ?? _data!['profileImage'],
                title: _composeTitle(_data!),
                subtitle: _composeSubtitle(_data!),
                chips: _composeChips(_data!),
                bio: (_data!['bio'] as String?) ?? '',
                isOnline: _data!['isOnline'] as bool? ?? false,
                // Only show actions when previewing someone else
                onPass: _isSelf() ? null : () => Navigator.maybePop(context),
                onLike: _isSelf() ? null : _handleLike,
                onMessage: _isSelf() ? null : () { Navigator.pushNamed(context, '/chat-list'); },
              ),
            ),
        ],
      ),
    );
  }

  String _composeTitle(Map<String, dynamic> d) {
    final name = (d['displayName'] ?? d['username'] ?? 'User').toString();
    final age = d['age'];
    return age is int ? '$name, $age' : name;
  }

  String? _composeSubtitle(Map<String, dynamic> d) {
    final loc = d['location'] as String?;
    return loc;
  }

  List<String> _composeChips(Map<String, dynamic> d) {
    final interests = (d['interests'] is List)
        ? List<String>.from(d['interests'])
        : <String>[];
    return interests.take(3).toList();
  }

  bool _isSelf() {
    final id = _data?['uid'] ?? _data?['id'];
    final selfId = _data?['currentUserId'];
    if (id != null && selfId != null) return id == selfId;
    // Fallback: if no userId was passed into screen, assume self preview
    return widget.userId == null;
  }
}


