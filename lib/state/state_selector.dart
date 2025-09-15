import 'package:flutter/material.dart';
import 'app_state.dart';

/// A widget that rebuilds only when specific parts of the state change
class StateSelector<T> extends StatelessWidget {
  final ValueNotifier<T> notifier;
  final Widget Function(BuildContext context, T value) builder;
  final T? initialValue;

  const StateSelector({
    super.key,
    required this.notifier,
    required this.builder,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: notifier,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when the current user changes
class UserSelector extends StatelessWidget {
  final Widget Function(BuildContext context, User? user) builder;

  const UserSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<User?>(
      notifier: AppState().currentUser,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when authentication status changes
class AuthSelector extends StatelessWidget {
  final Widget Function(BuildContext context, bool isAuthenticated) builder;

  const AuthSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<bool>(
      notifier: AppState().isAuthenticated,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when loading status changes
class LoadingSelector extends StatelessWidget {
  final Widget Function(BuildContext context, bool isLoading) builder;

  const LoadingSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<bool>(
      notifier: AppState().isLoading,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when credits change
class CreditsSelector extends StatelessWidget {
  final Widget Function(BuildContext context, int credits) builder;

  const CreditsSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<int>(
      notifier: AppState().credits,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when premium status changes
class PremiumSelector extends StatelessWidget {
  final Widget Function(BuildContext context, bool isPremium) builder;

  const PremiumSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<bool>(
      notifier: AppState().isPremium,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when friends list changes
class FriendsSelector extends StatelessWidget {
  final Widget Function(BuildContext context, List<User> friends) builder;

  const FriendsSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<List<User>>(
      notifier: AppState().friends,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when chats list changes
class ChatsSelector extends StatelessWidget {
  final Widget Function(BuildContext context, List<Chat> chats) builder;

  const ChatsSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<List<Chat>>(
      notifier: AppState().chats,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when current chat changes
class CurrentChatSelector extends StatelessWidget {
  final Widget Function(BuildContext context, Chat? chat) builder;

  const CurrentChatSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<Chat?>(
      notifier: AppState().currentChat,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when total unread count changes
class UnreadCountSelector extends StatelessWidget {
  final Widget Function(BuildContext context, int unreadCount) builder;

  const UnreadCountSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<int>(
      notifier: AppState().totalUnreadCount,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when matching status changes
class MatchingSelector extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMatching) builder;

  const MatchingSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<bool>(
      notifier: AppState().isMatching,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when connection status changes
class ConnectionSelector extends StatelessWidget {
  final Widget Function(BuildContext context, bool isConnected) builder;

  const ConnectionSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<bool>(
      notifier: AppState().isConnected,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when typing status changes
class TypingSelector extends StatelessWidget {
  final Widget Function(BuildContext context, bool isTyping, String? typingUser) builder;

  const TypingSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState().isTyping,
      builder: (context, isTyping, child) {
        return ValueListenableBuilder<String?>(
          valueListenable: AppState().typingUser,
          builder: (context, typingUser, child) {
            return builder(context, isTyping, typingUser);
          },
        );
      },
    );
  }
}

/// A widget that rebuilds only when current tab index changes
class TabIndexSelector extends StatelessWidget {
  final Widget Function(BuildContext context, int tabIndex) builder;

  const TabIndexSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<int>(
      notifier: AppState().currentTabIndex,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when search query changes
class SearchQuerySelector extends StatelessWidget {
  final Widget Function(BuildContext context, String? query) builder;

  const SearchQuerySelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<String?>(
      notifier: AppState().searchQuery,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when error state changes
class ErrorSelector extends StatelessWidget {
  final Widget Function(BuildContext context, String? error) builder;

  const ErrorSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<String?>(
      notifier: AppState().error,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when blocked users list changes
class BlockedUsersSelector extends StatelessWidget {
  final Widget Function(BuildContext context, List<User> blockedUsers) builder;

  const BlockedUsersSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<List<User>>(
      notifier: AppState().blockedUsers,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when friend requests list changes
class FriendRequestsSelector extends StatelessWidget {
  final Widget Function(BuildContext context, List<User> friendRequests) builder;

  const FriendRequestsSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<List<User>>(
      notifier: AppState().friendRequests,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when user interests change
class InterestsSelector extends StatelessWidget {
  final Widget Function(BuildContext context, List<String> interests) builder;

  const InterestsSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<List<String>>(
      notifier: AppState().interests,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when user profile image changes
class ProfileImageSelector extends StatelessWidget {
  final Widget Function(BuildContext context, String? profileImage) builder;

  const ProfileImageSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<String?>(
      notifier: AppState().profileImage,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when username changes
class UsernameSelector extends StatelessWidget {
  final Widget Function(BuildContext context, String? username) builder;

  const UsernameSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<String?>(
      notifier: AppState().username,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when online status changes
class OnlineStatusSelector extends StatelessWidget {
  final Widget Function(BuildContext context, bool isOnline) builder;

  const OnlineStatusSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<bool>(
      notifier: AppState().isOnline,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when queue time changes
class QueueTimeSelector extends StatelessWidget {
  final Widget Function(BuildContext context, int queueTime) builder;

  const QueueTimeSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<int>(
      notifier: AppState().queueTime,
      builder: builder,
    );
  }
}

/// A widget that rebuilds only when filters change
class FiltersSelector extends StatelessWidget {
  final Widget Function(BuildContext context, Map<String, dynamic> filters) builder;

  const FiltersSelector({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StateSelector<Map<String, dynamic>>(
      notifier: AppState().filters,
      builder: builder,
    );
  }
}
