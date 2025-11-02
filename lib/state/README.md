# Granular State Management System

This directory contains a new granular state management system that provides better performance and more efficient widget rebuilding compared to the traditional Provider pattern.

## Architecture Overview

The new state management system consists of:

1. **AppState** - Central state container using ValueNotifiers
2. **StateSelector** - Widgets that rebuild only when specific state changes
3. **StateManager** - Coordinates between services and state
4. **StateProvider** - Makes state available throughout the widget tree

## Key Benefits

### Performance Improvements
- **Granular Rebuilds**: Widgets only rebuild when their specific data changes
- **Reduced Widget Tree Rebuilds**: No more full app rebuilds on state changes
- **Better Memory Usage**: ValueNotifiers are more memory efficient than ChangeNotifier
- **Optimized List Performance**: List widgets only rebuild affected items

### Developer Experience
- **Type Safety**: Strongly typed state selectors
- **Easy Testing**: State can be easily mocked and tested
- **Clear Dependencies**: Explicit state dependencies through selectors
- **Better Debugging**: Clear separation of state concerns

## Usage Examples

### Basic Setup

```dart
// In main.dart
void main() {
  runApp(
    StateProvider(
      child: MyApp(),
    ),
  );
}

// In your app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppStateProviderBuilder(
      builder: (context, appState) {
        return MaterialApp(
          home: HomeScreen(),
        );
      },
    );
  }
}
```

### Using State Selectors

```dart
// Only rebuilds when user changes
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UserSelector(
      builder: (context, user) {
        if (user == null) {
          return LoginScreen();
        }
        return ProfileScreen(user: user);
      },
    );
  }
}

// Only rebuilds when credits change
class CreditsDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CreditsSelector(
      builder: (context, credits) {
        return Text('Credits: $credits');
      },
    );
  }
}

// Only rebuilds when chats change
class ChatList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChatsSelector(
      builder: (context, chats) {
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            return ChatItem(chat: chats[index]);
          },
        );
      },
    );
  }
}
```

### Accessing State Manager

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Access state manager
        final stateManager = context.stateManager;
        stateManager.startMatching();
      },
      child: Text('Start Matching'),
    );
  }
}
```

### Updating State

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Update state through state manager
        final stateManager = context.stateManager;
        stateManager.updateCredits(100);
      },
      child: Text('Add Credits'),
    );
  }
}
```

## Migration Guide

### From Provider to State Selectors

**Before (Provider):**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Text('Hello ${userProvider.currentUser?.username}');
      },
    );
  }
}
```

**After (State Selector):**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UsernameSelector(
      builder: (context, username) {
        return Text('Hello $username');
      },
    );
  }
}
```

### From setState to State Manager

**Before (setState):**
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int _credits = 0;

  void _updateCredits(int newCredits) {
    setState(() {
      _credits = newCredits;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('Credits: $_credits');
  }
}
```

**After (State Manager):**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CreditsSelector(
      builder: (context, credits) {
        return Text('Credits: $credits');
      },
    );
  }
}

// Update credits elsewhere
void updateCredits(BuildContext context, int newCredits) {
  context.stateManager.updateCredits(newCredits);
}
```

## Available State Selectors

### User State
- `UserSelector` - Current user
- `AuthSelector` - Authentication status
- `LoadingSelector` - Loading state
- `ErrorSelector` - Error state

### User Profile
- `UsernameSelector` - Username
- `ProfileImageSelector` - Profile image
- `CreditsSelector` - Credits
- `PremiumSelector` - Premium status
- `InterestsSelector` - User interests
- `OnlineStatusSelector` - Online status

### Social Features
- `FriendsSelector` - Friends list
- `BlockedUsersSelector` - Blocked users
- `FriendRequestsSelector` - Friend requests

### Chat Features
- `ChatsSelector` - Chats list
- `CurrentChatSelector` - Current chat
- `UnreadCountSelector` - Total unread count
- `TypingSelector` - Typing status

### Matching Features
- `MatchingSelector` - Matching status
- `ConnectionSelector` - Connection status
- `QueueTimeSelector` - Queue time
- `FiltersSelector` - Matching filters

### UI State
- `TabIndexSelector` - Current tab
- `SearchQuerySelector` - Search query

## Best Practices

### 1. Use Specific Selectors
```dart
// Good - Only rebuilds when credits change
CreditsSelector(
  builder: (context, credits) => Text('$credits'),
)

// Avoid - Rebuilds when any user data changes
UserSelector(
  builder: (context, user) => Text('${user?.credits}'),
)
```

### 2. Combine Selectors When Needed
```dart
// Good - Combines multiple related selectors
Widget build(BuildContext context) {
  return ValueListenableBuilder<bool>(
    valueListenable: AppState().isLoading,
    builder: (context, isLoading, child) {
      return ValueListenableBuilder<String?>(
        valueListenable: AppState().error,
        builder: (context, error, child) {
          if (isLoading) return CircularProgressIndicator();
          if (error != null) return Text('Error: $error');
          return child!;
        },
        child: YourContent(),
      );
    },
  );
}
```

### 3. Use RepaintBoundary for Complex Widgets
```dart
// Good - Prevents unnecessary repaints
RepaintBoundary(
  child: ComplexWidget(),
)
```

### 4. Dispose Resources Properly
```dart
@override
void dispose() {
  // State manager handles disposal automatically
  super.dispose();
}
```

## Performance Tips

1. **Use const constructors** where possible
2. **Wrap expensive widgets** with RepaintBoundary
3. **Use specific selectors** instead of broad ones
4. **Avoid rebuilding** the entire widget tree
5. **Use ValueListenableBuilder** for custom state combinations

## Testing

The granular state system is designed to be easily testable:

```dart
testWidgets('should display user credits', (tester) async {
  // Create test state
  final appState = AppState();
  appState.updateCredits(100);

  // Build widget
  await tester.pumpWidget(
    StateProvider(
      stateManager: StateManager(),
      child: CreditsSelector(
        builder: (context, credits) => Text('$credits'),
      ),
    ),
  );

  // Verify
  expect(find.text('100'), findsOneWidget);
});
```

## Future Enhancements

- [ ] State persistence
- [ ] State time travel debugging
- [ ] Automatic state synchronization
- [ ] State validation
- [ ] State middleware support
