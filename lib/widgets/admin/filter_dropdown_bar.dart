import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterGroupData {
  final String label;
  final List<String> options;
  final String Function(String) labelFor;
  final String selected;
  final ValueChanged<String> onSelect;

  const FilterGroupData({
    required this.label,
    required this.options,
    required this.labelFor,
    required this.selected,
    required this.onSelect,
  });
}

class FilterDropdownBar extends StatefulWidget {
  final String summaryText;
  final bool hasActiveFilter;
  final Color accentColor;
  final List<FilterGroupData> groups;
  final int? count;

  const FilterDropdownBar({
    super.key,
    required this.summaryText,
    required this.hasActiveFilter,
    required this.accentColor,
    required this.groups,
    this.count,
  });

  @override
  State<FilterDropdownBar> createState() => _FilterDropdownBarState();
}

class _FilterDropdownBarState extends State<FilterDropdownBar> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _barrierEntry;
  bool _isOpen = false;

  @override
  void didUpdateWidget(FilterDropdownBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Defer markNeedsBuild to avoid calling it during a parent build phase.
    if (_isOpen && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isOpen) _overlayEntry?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _barrierEntry?.remove();
    _barrierEntry = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      setState(() => _isOpen = true);
      final overlay = Overlay.of(context);
      _barrierEntry = OverlayEntry(
        builder: (_) => GestureDetector(
          onTap: _removeOverlay,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(
            child: ColoredBox(color: Colors.transparent),
          ),
        ),
      );
      _overlayEntry = OverlayEntry(builder: _buildPanel);
      overlay.insertAll([_barrierEntry!, _overlayEntry!]);
    }
  }

  Widget _buildPanel(BuildContext ctx) {
    final groupCount = widget.groups.length;
    final dropdownWidth = groupCount == 1 ? 220.0 : 420.0;

    return Positioned(
      top: 0,
      left: 0,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: const Offset(0, 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dropdownWidth),
          child: Material(
            elevation: 12,
            shadowColor: Colors.black.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              // IntrinsicHeight prevents the Row from expanding to screen height.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < widget.groups.length; i++) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          color: const Color(0xFFE5E7EB),
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.groups[i].label,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB0B7C3),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: widget.groups[i].options.map((opt) {
                                final active = opt == widget.groups[i].selected;
                                return GestureDetector(
                                  onTap: () {
                                    widget.groups[i].onSelect(opt);
                                    // setState is deferred via didUpdateWidget +
                                    // addPostFrameCallback, so no direct call here.
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? widget.accentColor
                                          : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.groups[i].labelFor(opt),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: active
                                            ? Colors.white
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _toggleDropdown,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                if (widget.count != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.count} items',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (widget.hasActiveFilter)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  widget.summaryText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.hasActiveFilter
                        ? widget.accentColor
                        : const Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.hasActiveFilter
                        ? widget.accentColor.withOpacity(0.08)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.hasActiveFilter
                          ? widget.accentColor.withOpacity(0.3)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: widget.hasActiveFilter
                            ? widget.accentColor
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Filter',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: widget.hasActiveFilter
                              ? widget.accentColor
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      if (widget.hasActiveFilter) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(
                        _isOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: widget.hasActiveFilter
                            ? widget.accentColor
                            : const Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
