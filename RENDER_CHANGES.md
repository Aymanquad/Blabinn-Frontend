# Render Deployment Changes - Reference Guide

This document lists all changes made for Render deployment and UI fixes. Use this as a reference when reverting to older commits.

## Date: November 2, 2025

---

## 1. Backend URL Configuration Fix

### File: `lib/core/env_config.dart`

**Changes:** Updated all backend URLs from `blabbin-backend.onrender.com` to `blabbin-backend-rsss.onrender.com`

**Lines to modify:**
```dart
// API Configuration
static const String apiBaseUrlAndroid =
    'https://blabbin-backend-rsss.onrender.com';
static const String apiBaseUrlIos = 'https://blabbin-backend-rsss.onrender.com';
static const String apiBaseUrlWeb = 'https://blabbin-backend-rsss.onrender.com';
static const String apiBaseUrlDefault =
    'https://blabbin-backend-rsss.onrender.com';

// WebSocket Configuration
static const String wsUrlAndroid = 'https://blabbin-backend-rsss.onrender.com';
static const String wsUrlIos = 'https://blabbin-backend-rsss.onrender.com';
static const String wsUrlWeb = 'https://blabbin-backend-rsss.onrender.com';
static const String wsUrlDefault = 'https://blabbin-backend-rsss.onrender.com';
```

---

## 2. AppBar Purple Theme Fix

### File: `lib/app.dart`

**Changes:** Restored purple AppBar background with white text/icons

**Location:** Around line 871-910 in `build()` method

**Code to add:**
```dart
appBar: AppBar(
  backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
  foregroundColor: Colors.white,
  leading: IconButton(
    icon: AnimatedBuilder(
      animation: _drawerAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _drawerAnimation.value * 0.5,
          child: const Icon(
            Icons.menu,
            color: Colors.white,
          ),
        );
      },
    ),
    onPressed: () {
      _drawerAnimationController.forward();
      _scaffoldKey.currentState?.openDrawer();
    },
    tooltip: 'Menu',
  ),
  title: Text(
    AppConstants.appName,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  actions: [
    IconButton(
      icon: const Icon(
        AppIcons.profile,
        color: Colors.white,
      ),
      onPressed: _navigateToProfile,
      tooltip: 'Profile',
    ),
  ],
  centerTitle: true,
),
```

---

## 3. Glassmorphic Purple Navbar

### File: `lib/app.dart`

**Changes:** Complete replacement of bottom navigation bar with glassmorphic design

**Location:** Replace `_buildGlassmorphicNavBar()` method (around line 953)

**Key Features:**
- Purple gradient background with glassmorphism (backdrop blur)
- Animated sliding indicator background
- Bounce animations on selection
- Modern rounded corners
- White text/icons on purple background

**Full Method Code:**
```dart
Widget _buildGlassmorphicNavBar(BuildContext context, bool isDark) {
  final navItems = [
    {'icon': AppIcons.home, 'label': AppStrings.home},
    {'icon': AppIcons.chat, 'label': AppStrings.chats},
    {'icon': AppIcons.connect, 'label': AppStrings.connect},
    {'icon': AppIcons.media, 'label': AppStrings.media},
  ];

  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 25,
          offset: const Offset(0, -8),
          spreadRadius: 0,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.darkPrimary.withOpacity(0.9),
                      AppColors.darkPrimary.withOpacity(0.7),
                      AppColors.darkPrimary.withOpacity(0.85),
                    ]
                  : [
                      AppColors.primary.withOpacity(0.9),
                      AppColors.primary.withOpacity(0.75),
                      AppColors.primary.withOpacity(0.85),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Animated sliding indicator background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                left: (_currentIndex * MediaQuery.of(context).size.width / 4),
                top: 8,
                bottom: 8,
                child: Container(
                  width: MediaQuery.of(context).size.width / 4 - 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Nav items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(navItems.length, (index) {
                  final isSelected = _currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabTapped(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedBuilder(
                        animation: _navItemControllers[index],
                        builder: (context, child) {
                          final bounceValue = Curves.elasticOut.transform(
                            _navItemControllers[index].value,
                          );
                          final opacity = isSelected
                              ? 1.0 - (bounceValue * 0.2)
                              : 0.5 + (bounceValue * 0.5);

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Animated icon with bounce
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 1.0 + (value * 0.15),
                                      child: Transform.translate(
                                        offset: Offset(0, -value * 3),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: isSelected
                                                ? RadialGradient(
                                                    colors: [
                                                      Colors.white.withOpacity(0.4),
                                                      Colors.white.withOpacity(0.1),
                                                    ],
                                                  )
                                                : null,
                                          ),
                                          child: Icon(
                                            navItems[index]['icon'] as IconData,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white.withOpacity(opacity),
                                            size: isSelected ? 28 : 24,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                // Animated label with fade
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(opacity),
                                    fontSize: isSelected ? 12 : 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    letterSpacing: 0.8,
                                    shadows: isSelected
                                        ? [
                                            Shadow(
                                              color: Colors.white.withOpacity(0.5),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    navItems[index]['label'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

---

## 4. Enhanced Tab Navigation Animation

### File: `lib/app.dart`

**Changes:** Improved `_onTabTapped()` method with bounce animations

**Location:** Around line 507

**Code to replace:**
```dart
void _onTabTapped(int index) {
  if (_currentIndex == index) return; // Prevent re-tapping same tab
  
  // Animate out previous selection
  _navItemControllers[_currentIndex].reverse();
  
  setState(() {
    _currentIndex = index;
  });
  
  // Animate in new selection with bounce
  _navItemControllers[index].forward(from: 0.0).then((_) {
    // Bounce back effect
    _navItemControllers[index].reverse().then((_) {
      _navItemControllers[index].forward();
    });
  });
  
  _pageController.animateToPage(
    index,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}
```

---

## 5. Required Import

### File: `lib/app.dart`

**Changes:** Added Flutter Material import at the top

**Location:** Line 2

**Code to add:**
```dart
import 'package:flutter/material.dart';
```

**Make sure this import exists:**
```dart
import 'dart:ui';
import 'package:flutter/material.dart';  // <-- ADD THIS
import 'package:firebase_auth/firebase_auth.dart';
// ... rest of imports
```

---

## 6. Bottom Navigation Bar Usage

### File: `lib/app.dart`

**Changes:** Ensure bottomNavigationBar uses the glassmorphic navbar

**Location:** In `build()` method around line 949

**Code:**
```dart
bottomNavigationBar: _buildGlassmorphicNavBar(context, isDark),
```

---

## Summary Checklist

When reverting to an older commit, apply these changes:

- [ ] Update backend URLs in `lib/core/env_config.dart` (Change `-rsss` suffix)
- [ ] Fix AppBar purple theme in `lib/app.dart` (Add purple background, white text)
- [ ] Replace `_buildGlassmorphicNavBar()` method with new glassmorphic version
- [ ] Update `_onTabTapped()` method with bounce animations
- [ ] Ensure `import 'package:flutter/material.dart';` exists
- [ ] Verify `bottomNavigationBar` uses `_buildGlassmorphicNavBar()`

---

## Notes

- Keep-alive HTML files (`keep-alive.html` in backend/chatbot/redis folders) are optional local utilities and don't need to be committed
- These changes are specifically for Render deployment and UI improvements
- The glassmorphic navbar requires `dart:ui` import for `ImageFilter`

---

## Testing After Applying Changes

1. Hot restart the app (not hot reload)
2. Verify purple AppBar appears
3. Check purple glassmorphic navbar at bottom
4. Test tab switching animations
5. Verify backend connectivity with correct URL



