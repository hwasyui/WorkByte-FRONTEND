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
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
