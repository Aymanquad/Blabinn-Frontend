import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class CreditsDisplay extends StatelessWidget {
  final double? size;
  final Color? textColor;
  final Color? backgroundColor;
  final bool showIcon;

  const CreditsDisplay({
    Key? key,
    this.size,
    this.textColor,
    this.backgroundColor,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        final credits = user?.credits ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  Icons.monetization_on,
                  size: (size ?? 16) - 2,
                  color: textColor ?? Colors.green,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '$credits',
                style: TextStyle(
                  fontSize: size ?? 16,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.green,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'credits',
                style: TextStyle(
                  fontSize: (size ?? 16) - 2,
                  color: textColor?.withOpacity(0.7) ??
                      Colors.green.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CreditsDisplaySmall extends StatelessWidget {
  final VoidCallback? onTap;

  const CreditsDisplaySmall({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child = const CreditsDisplay(
      size: 14,
      showIcon: true, // Show icon to make it more obvious it's interactive
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: child,
        ),
      );
    }

    return child;
  }
}

class CreditsDisplayLarge extends StatelessWidget {
  const CreditsDisplayLarge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CreditsDisplay(
      size: 18,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }
}
