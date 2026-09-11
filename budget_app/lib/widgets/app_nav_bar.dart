import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating frosted navigation bar that content scrolls underneath.
///
/// Screens must keep [contentInset] of free space at the bottom of their
/// scrollables so nothing ends up hidden behind the bar.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.items,
  });

  static const double barHeight = 64;
  static const double _sideMargin = 16;
  static const double _minBottomMargin = 12;

  /// Height the bar occupies, including the gap below it.
  static double reservedHeight(BuildContext context) =>
      barHeight +
      math.max(MediaQuery.of(context).viewPadding.bottom, _minBottomMargin);

  /// Bottom padding a scrollable needs so its last item clears the bar.
  static double contentInset(BuildContext context) =>
      reservedHeight(context) + 12;

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<AppNavItem> items;

  @override
  Widget build(BuildContext context) {
    final bottomMargin = math.max(
      MediaQuery.of(context).viewPadding.bottom,
      _minBottomMargin,
    );
    final radius = BorderRadius.circular(AppRadius.xl);

    return Padding(
      padding: EdgeInsets.fromLTRB(_sideMargin, 0, _sideMargin, bottomMargin),
      child: DecoratedBox(
        // The shadow lives outside the clip so it is not cut off.
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.floating,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavButton(
                        item: items[i],
                        selected: i == currentIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 21,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
