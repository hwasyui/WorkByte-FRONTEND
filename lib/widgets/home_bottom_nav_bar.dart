import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final bool showCenterButton; // kept for API compatibility, no longer used

  const HomeBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.showCenterButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAEAEA).withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(4, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            isSelected: currentIndex == 0,
            onTap: () => onTap?.call(0),
          ),
          _NavItem(
            icon: Icons.list_alt_outlined,
            activeIcon: Icons.list_alt_rounded,
            isSelected: currentIndex == 1,
            onTap: () => onTap?.call(1),
          ),
          _NavItem(
            icon: Icons.work_outline_rounded,
            activeIcon: Icons.work_rounded,
            isSelected: currentIndex == 2,
            onTap: () => onTap?.call(2),
          ),
          _NavItem(
            icon: Icons.group_outlined,
            activeIcon: Icons.group_rounded,
            isSelected: currentIndex == 3,
            onTap: () => onTap?.call(3),
          ),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person_rounded,
            isSelected: currentIndex == 4,
            onTap: () => onTap?.call(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          isSelected ? activeIcon : icon,
          size: 25,
          color: isSelected ? AppColors.primary : const Color(0xFF7D7D7D),
        ),
      ),
    );
  }
}
