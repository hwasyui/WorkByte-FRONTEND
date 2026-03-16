import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const HomeBottomNavBar({super.key, this.currentIndex = 0, this.onTap});

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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Nav icons row
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  isSelected: currentIndex == 0,
                  onTap: () => onTap?.call(0),
                ),
                _NavItem(
                  icon: Icons.list_alt_outlined,
                  isSelected: currentIndex == 1,
                  onTap: () => onTap?.call(1),
                ),
                // Center spacer for FAB
                const SizedBox(width: 60),
                _NavItem(
                  icon: Icons.group_outlined,
                  isSelected: currentIndex == 3,
                  onTap: () => onTap?.call(3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  isSelected: currentIndex == 4,
                  onTap: () => onTap?.call(4),
                ),
              ],
            ),
          ),
          // Floating center button
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => onTap?.call(2),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.25),
                        blurRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _NavItem({required this.icon, this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          icon,
          size: 25,
          color: isSelected ? AppColors.primary : const Color(0xFF7D7D7D),
        ),
      ),
    );
  }
}
