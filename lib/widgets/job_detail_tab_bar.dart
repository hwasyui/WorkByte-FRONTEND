import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

/// Reusable tab bar for job detail screens (Details / Terms / Bidding).
class JobDetailTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const JobDetailTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(tabs.length, (i) {
            final isSelected = i == selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabSelected(i),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.only(bottom: 8),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF7D7D7D),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        // Underline indicator row
        Row(
          children: List.generate(tabs.length, (i) {
            final isSelected = i == selectedIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isSelected ? AppColors.primary : const Color(0xFFDCDEDE),
              ),
            );
          }),
        ),
      ],
    );
  }
}
