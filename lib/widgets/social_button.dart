import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String assetPath;
  final double iconSize;
  final VoidCallback? onPressed;

  const SocialButton({
    super.key,
    required this.assetPath,
    this.iconSize = 34,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60, 
        height: 60, 
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all( 
            color: const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: iconSize - 6, 
            height: iconSize - 6,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}