import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriendRequests();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh friend requests when screen becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFriendRequests();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final incoming = await _apiService.getIncomingFriendRequests();
      final outgoing = await _apiService.getOutgoingFriendRequests();

      setState(() {
        _incomingRequests = incoming;
        _outgoingRequests = outgoing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load friend requests: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(String connectionId) async {
    try {
      print('🔍 [FRIEND_REQUESTS] Accepting friend request: $connectionId');
      await _apiService.acceptFriendRequest(connectionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request accepted!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload to update the list immediately
        await _loadFriendRequests();
      }
    } catch (e) {
      print('❌ [FRIEND_REQUESTS] Failed to accept request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String connectionId) async {
    try {
      print('🔍 [FRIEND_REQUESTS] Rejecting friend request: $connectionId');
      await _apiService.rejectFriendRequest(connectionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request rejected'),
            backgroundColor: Colors.orange,
          ),
        );

        // Reload to update the list immediately
        await _loadFriendRequests();
      }
    } catch (e) {
      print('❌ [FRIEND_REQUESTS] Failed to reject request: $e');
      if (mounted) {
        String errorMessage = 'Failed to reject request';
        if (e.toString().contains('Request not found')) {
          errorMessage = 'Request no longer exists or was already processed.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );

        // Still reload the list in case the request was processed
        await _loadFriendRequests();
      }
    }
  }

  Future<void> _cancelRequest(String connectionId) async {
    try {
      print('🔍 [FRIEND_REQUESTS] Cancelling friend request: $connectionId');
      await _apiService.cancelFriendRequest(connectionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request cancelled'),
            backgroundColor: Colors.orange,
          ),
        );

        // Reload to update the list immediately
        await _loadFriendRequests();
      }
    } catch (e) {
      print('❌ [FRIEND_REQUESTS] Failed to cancel request: $e');
      if (mounted) {
        String errorMessage = 'Failed to cancel request';
        if (e.toString().contains('Request not found')) {
          errorMessage = 'Request no longer exists or was already processed.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );

        // Still reload the list in case the request was processed
        await _loadFriendRequests();
      }
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> request, bool isIncoming) {
    // Get the user data based on whether it's incoming or outgoing
    final userData = isIncoming ? request['fromUser'] : request['toUser'];
    final connectionId =
        request['id'] as String? ?? request['_id'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: userData?['profilePicture'] != null
                      ? NetworkImage(userData['profilePicture'])
                      : null,
                  child: userData?['profilePicture'] == null
                      ? Text(
                          (userData?['displayName'] ??
                                  userData?['username'] ??
                                  '?')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData?['displayName']?.toString() ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${userData?['username']?.toString() ?? 'unknown'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request['message'] != null &&
                request['message'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  request['message']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: isIncoming
                  ? [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptRequest(connectionId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectRequest(connectionId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    ]
                  : [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelRequest(connectionId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel Request'),
                        ),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
      List<Map<String, dynamic>> requests, bool isIncoming) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFriendRequests,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIncoming ? Icons.inbox_outlined : Icons.outbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isIncoming ? 'No Incoming Requests' : 'No Outgoing Requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isIncoming
                  ? 'You don\'t have any pending friend requests'
                  : 'You haven\'t sent any friend requests',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriendRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(requests[index], isIncoming);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friend Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox),
                  const SizedBox(width: 8),
                  Text('Incoming (${_incomingRequests.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.outbox),
                  const SizedBox(width: 8),
                  Text('Outgoing (${_outgoingRequests.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(_incomingRequests, true),
          _buildTabContent(_outgoingRequests, false),
        ],
      ),
    );
  }
}
