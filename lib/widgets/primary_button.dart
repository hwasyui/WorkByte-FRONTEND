import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height + 6, 
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient( 
              colors: [
                AppColors.primary,
                const Color(0xFF6366F1),
              ],
            ),
            borderRadius: BorderRadius.circular(30), 
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Row( 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppText.captionSemiBold.copyWith(
                    color: Colors.white,
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                // const Icon(
                //   Icons.arrow_forward, 
                //   color: Colors.white,
                //   size: 18,
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}