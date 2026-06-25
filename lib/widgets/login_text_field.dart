import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class LoginTextField extends StatefulWidget {
  final String hintText;
  final Widget prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? errorText;

  const LoginTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.errorText,
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
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: hasError
                    ? Colors.red
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow( 
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 18), 

                // ICON
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconTheme( 
                    data: const IconThemeData(
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                    child: widget.prefixIcon,
                  ),
                ),

                const SizedBox(width: 12),

                // TEXTFIELD
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    obscureText: widget.isPassword && _obscure,
                    keyboardType: widget.keyboardType,
                    style: AppText.caption.copyWith(
                      color: const Color(0xFF111827),
                      fontSize: 14, 
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: AppText.caption.copyWith(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, 
                      ),
                    ),
                  ),
                ),

                // PASSWORD ICON
                if (widget.isPassword) ...[
                  GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_outlined 
                            : Icons.visibility_off_outlined,
                        size: 22,
                        color: const Color(0xFF4F46E5), 
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(width: 16),
              ],
            ),
          ),
        ),

        // ERROR TEXT
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 18), 
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}