import 'package:flutter/material.dart';
import '../core/constants.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String remoteUserId;
  final bool isIncoming;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.remoteUserId,
    this.isIncoming = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  bool _isCallConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  void _initializeCall() {
    // TODO: Initialize WebRTC connection
    if (!widget.isIncoming) {
      _startCall();
    }
  }

  void _startCall() {
    // TODO: Implement call start logic
    setState(() {
      _isCallConnected = true;
    });
    _startTimer();
  }

  void _startTimer() {
    // TODO: Implement call duration timer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          _buildRemoteVideo(),
          
          // Local video (picture-in-picture)
          _buildLocalVideo(),
          
          // Call controls
          _buildCallControls(),
          
          // Call info
          _buildCallInfo(),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: _isCallConnected
            ? const Text(
                'Remote Video',
                style: TextStyle(color: Colors.white),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLocalVideo() {
    return Positioned(
      top: 60,
      right: 20,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _isVideoEnabled
              ? const Center(
                  child: Text(
                    'Local Video',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Container(
                  color: Colors.black,
                  child: const Icon(
                    Icons.videocam_off,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCallInfo() {
    return Positioned(
      top: 60,
      left: 20,
      right: 160,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calling...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '00:00',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // Top row controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? AppColors.error : Colors.white,
                  onPressed: _toggleMute,
                ),
                _buildControlButton(
                  icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  color: _isVideoEnabled ? Colors.white : AppColors.error,
                  onPressed: _toggleVideo,
                ),
                _buildControlButton(
                  icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  color: Colors.white,
                  onPressed: _toggleSpeaker,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Bottom row controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.switch_camera,
                  color: Colors.white,
                  onPressed: _switchCamera,
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  color: AppColors.error,
                  backgroundColor: AppColors.error,
                  onPressed: _endCall,
                  isLarge: true,
                ),
                _buildControlButton(
                  icon: Icons.more_vert,
                  color: Colors.white,
                  onPressed: _showMoreOptions,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return Container(
      width: isLarge ? 80 : 60,
      height: isLarge ? 80 : 60,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: isLarge ? 3 : 2,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        iconSize: isLarge ? 32 : 24,
      ),
    );
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // TODO: Implement mute functionality
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    // TODO: Implement video toggle functionality
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    // TODO: Implement speaker toggle functionality
  }

  void _switchCamera() {
    // TODO: Implement camera switch functionality
  }

  void _endCall() {
    // TODO: Implement call end functionality
    Navigator.pop(context);
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.text.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over),
              title: const Text('Record Call'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement call recording
              },
            ),
            ListTile(
              leading: const Icon(Icons.screen_share),
              title: const Text('Screen Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement screen sharing
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to chat
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

}