import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DateRangeFilterButton extends StatelessWidget {
  final DateTimeRange? range;
  final ValueChanged<DateTimeRange?> onChanged;
  final Color accentColor;

  const DateRangeFilterButton({
    super.key,
    required this.range,
    required this.onChanged,
    this.accentColor = const Color(0xFF4F46E5),
  });

  String get _label {
    if (range == null) return 'Date range';
    String f(DateTime d) => '${d.day}/${d.month}/${d.year}';
    return '${f(range!.start)} – ${f(range!.end)}';
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => _DateRangeDialog(initialRange: range, accentColor: accentColor),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final active = range != null;
    return GestureDetector(
      onTap: () => _pick(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accentColor.withOpacity(0.08) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? accentColor.withOpacity(0.3) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 14,
              color: active ? accentColor : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 5),
            Text(
              _label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? accentColor : const Color(0xFF6B7280),
              ),
            ),
            if (active) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => onChanged(null),
                behavior: HitTestBehavior.opaque,
                child: Icon(Icons.close_rounded, size: 14, color: accentColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateRangeDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  final Color accentColor;

  const _DateRangeDialog({required this.initialRange, required this.accentColor});

  @override
  State<_DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<_DateRangeDialog> {
  DateTime? _start;
  DateTime? _end;
  bool _editingEnd = false;
  late DateTime _firstDate;
  late DateTime _lastDate;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
    final now = DateTime.now();
    _lastDate = now;
    _firstDate = DateTime(now.year - 5);
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  void _onDateChanged(DateTime picked) {
    setState(() {
      if (_editingEnd) {
        _end = picked;
        if (_start != null && _end!.isBefore(_start!)) {
          _start = _end;
        }
      } else {
        _start = picked;
        if (_end != null && _end!.isBefore(_start!)) {
          _end = null;
        }
        _editingEnd = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final canConfirm = _start != null && _end != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Date Range',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DateBox(
                        label: 'Start Date',
                        value: _fmt(_start),
                        active: !_editingEnd,
                        accentColor: accent,
                        onTap: () => setState(() => _editingEnd = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateBox(
                        label: 'End Date',
                        value: _fmt(_end),
                        active: _editingEnd,
                        accentColor: accent,
                        onTap: () => setState(() => _editingEnd = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(primary: accent),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: CalendarDatePicker(
                      initialDate: (_editingEnd ? _end : _start) ??
                          _start ??
                          DateTime.now(),
                      firstDate: _firstDate,
                      lastDate: _lastDate,
                      onDateChanged: _onDateChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: canConfirm
                          ? () => Navigator.pop(
                                context,
                                DateTimeRange(start: _start!, end: _end!),
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        disabledBackgroundColor: accent.withOpacity(0.4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;

  const _DateBox({
    required this.label,
    required this.value,
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? accentColor : const Color(0xFFE5E7EB),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value == 'Select date' ? const Color(0xFFD1D5DB) : const Color(0xFF111827),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
