import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final VoidCallback? onCenterTap;
  final bool showCenterButton;

  const HomeBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.onCenterTap,
    this.showCenterButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap?.call(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.work_outline_rounded,
                    activeIcon: Icons.work_rounded,
                    label: 'Jobs',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap?.call(1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.list_alt_outlined,
                    activeIcon: Icons.list_alt_rounded,
                    label: 'Workspace',
                    isSelected: currentIndex == 2,
                    onTap: () => onTap?.call(2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: 'Messages',
                    isSelected: currentIndex == 3,
                    onTap: () => onTap?.call(3),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showCenterButton)
          Positioned(
            top: -34,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onCenterTap,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 84,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected ? AppColors.primary : const Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}