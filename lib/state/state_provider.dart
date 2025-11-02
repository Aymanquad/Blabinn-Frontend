import 'package:flutter/material.dart';
import 'state_manager.dart';

/// A provider widget that makes the StateManager available throughout the widget tree
class StateProvider extends StatefulWidget {
  final Widget child;
  final StateManager? stateManager;

  const StateProvider({
    super.key,
    required this.child,
    this.stateManager,
  });

  @override
  State<StateProvider> createState() => _StateProviderState();

  /// Get the StateManager from the current context
  static StateManager of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_StateProviderInherited>();
    if (provider == null) {
      throw FlutterError(
        'StateProvider.of() called with a context that does not contain a StateProvider.\n'
        'No ancestor could be found starting from the context that was passed to StateProvider.of().\n'
        'The context used was:\n'
        '  $context',
      );
    }
    return provider.stateManager;
  }

  /// Get the StateManager from the current context, or null if not found
  static StateManager? maybeOf(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_StateProviderInherited>();
    return provider?.stateManager;
  }
}

class _StateProviderState extends State<StateProvider> {
  late StateManager _stateManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _stateManager = widget.stateManager ?? StateManager();
    _initializeStateManager();
  }

  Future<void> _initializeStateManager() async {
    try {
      await _stateManager.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // Handle initialization error
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _stateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StateProviderInherited(
      stateManager: _stateManager,
      isInitialized: _isInitialized,
      child: widget.child,
    );
  }
}

class _StateProviderInherited extends InheritedWidget {
  final StateManager stateManager;
  final bool isInitialized;

  const _StateProviderInherited({
    required this.stateManager,
    required this.isInitialized,
    required super.child,
  });

  @override
  bool updateShouldNotify(_StateProviderInherited oldWidget) {
    return stateManager != oldWidget.stateManager ||
           isInitialized != oldWidget.isInitialized;
  }
}

/// A widget that shows a loading indicator while the state manager is initializing
class StateProviderBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, StateManager stateManager) builder;
  final Widget? loadingWidget;

  const StateProviderBuilder({
    super.key,
    required this.builder,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_StateProviderInherited>();
    
    if (provider == null) {
      throw FlutterError(
        'StateProviderBuilder used outside of StateProvider.\n'
        'Make sure StateProviderBuilder is a descendant of StateProvider.',
      );
    }

    if (!provider.isInitialized) {
      return loadingWidget ?? const Center(
        child: CircularProgressIndicator(),
      );
    }

    return builder(context, provider.stateManager);
  }
}

/// A widget that provides access to the app state
class AppStateProvider extends StatelessWidget {
  final Widget Function(BuildContext context, AppState appState) builder;

  const AppStateProvider({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final stateManager = StateProvider.of(context);
    return builder(context, stateManager.appState);
  }
}

/// A widget that provides access to the app state with loading state
class AppStateProviderBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AppState appState) builder;
  final Widget? loadingWidget;

  const AppStateProviderBuilder({
    super.key,
    required this.builder,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return StateProviderBuilder(
      loadingWidget: loadingWidget,
      builder: (context, stateManager) {
        return builder(context, stateManager.appState);
      },
    );
  }
}

/// Extension on BuildContext for easy access to StateManager
extension StateProviderExtension on BuildContext {
  /// Get the StateManager from the current context
  StateManager get stateManager => StateProvider.of(this);

  /// Get the AppState from the current context
  AppState get appState => StateProvider.of(this).appState;
}
