import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String)? onSearch;

  const SearchBarWidget({super.key, this.onSearch});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSearch?.call(_controller.text.trim());
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0F0F1)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              style: AppText.caption.copyWith(color: const Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: 'Search jobs...',
                hintStyle: AppText.caption.copyWith(
                  color: const Color(0xFF7D7D7D),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (_, value, __) {
              if (value.text.isNotEmpty) {
                return GestureDetector(
                  onTap: () {
                    _controller.clear();
                    widget.onSearch?.call('');
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.close,
                      color: Color(0xFF7D7D7D),
                      size: 18,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          GestureDetector(
            onTap: _submit,
            child: const Icon(
              Icons.search,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
