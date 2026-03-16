import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';

class LoginTextField extends StatefulWidget {
  final String hintText;
  final Widget prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  const LoginTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<LoginTextField> {
  bool _obscure = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector on the whole container ensures tapping anywhere
    // (icon, padding, etc.) requests focus and opens the keyboard.
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0F0F1)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 13),
            SizedBox(width: 30, height: 30, child: widget.prefixIcon),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                obscureText: widget.isPassword && _obscure,
                keyboardType: widget.keyboardType,
                style: AppText.caption.copyWith(color: const Color(0xFF333333)),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: AppText.caption.copyWith(
                    color: const Color(0xFF7D7D7D),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (widget.isPassword) ...[
              GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Padding(
                  padding: const EdgeInsets.only(right: 13),
                  child: Icon(
                    _obscure
                        ? Icons.remove_red_eye_outlined
                        : Icons.visibility_off_outlined,
                    size: 25,
                    color: const Color(0xFF7D7D7D),
                  ),
                ),
              ),
            ] else
              const SizedBox(width: 13),
          ],
        ),
      ),
    );
  }
}
