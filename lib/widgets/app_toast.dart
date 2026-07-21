import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import '../core/constants/text_styles.dart';

/// The three visual variants a toast can render as.
enum AppToastType { success, error, info }

/// One queued/displayed toast entry.
class _AppToastItem {
  final int id;
  final String message;
  final String title;
  final AppToastType type;
  final Duration duration;

  _AppToastItem({
    required this.id,
    required this.message,
    required this.title,
    required this.type,
    required this.duration,
  });
}

/// Global, queue-based toast controller. Only one toast is ever visible at a
/// time — if a new one is triggered while another is showing, it waits its
/// turn instead of stacking/overlapping on screen.
class AppToastController extends ChangeNotifier {
  AppToastController._();
  static final AppToastController instance = AppToastController._();

  final Queue<_AppToastItem> _queue = Queue<_AppToastItem>();
  _AppToastItem? _current;
  Timer? _timer;
  int _nextId = 0;

  _AppToastItem? get current => _current;

  void enqueue({
    required String message,
    required String title,
    required AppToastType type,
    required Duration duration,
  }) {
    final item = _AppToastItem(
      id: _nextId++,
      message: message,
      title: title,
      type: type,
      duration: duration,
    );
    _queue.add(item);
    if (_current == null) _advance();
  }

  void _advance() {
    _timer?.cancel();
    if (_queue.isEmpty) {
      _current = null;
      notifyListeners();
      return;
    }
    _current = _queue.removeFirst();
    notifyListeners();
    _timer = Timer(_current!.duration, _advance);
  }

  /// Dismisses the toast currently on screen (e.g. user tapped close) and
  /// immediately shows the next queued one, if any.
  void dismissCurrent() {
    if (_current == null) return;
    _advance();
  }
}

/// Static, context-free API for showing toasts from anywhere in the app.
class AppToast {
  AppToast._();

  static void success(
    String message, {
    String title = 'Success',
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToastController.instance.enqueue(
      message: message,
      title: title,
      type: AppToastType.success,
      duration: duration,
    );
  }

  static void error(
    String message, {
    String title = 'Error',
    Duration duration = const Duration(seconds: 4),
  }) {
    AppToastController.instance.enqueue(
      message: message,
      title: title,
      type: AppToastType.error,
      duration: duration,
    );
  }

  static void info(
    String message, {
    String title = 'Notice',
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToastController.instance.enqueue(
      message: message,
      title: title,
      type: AppToastType.info,
      duration: duration,
    );
  }
}

/// Mount once near the root of the app (see [main.dart]'s `MaterialApp.builder`).
/// Renders the currently active toast, if any, floating above [child].
class AppToastHost extends StatefulWidget {
  final Widget child;
  const AppToastHost({super.key, required this.child});

  @override
  State<AppToastHost> createState() => _AppToastHostState();
}

class _AppToastHostState extends State<AppToastHost> {
  @override
  void initState() {
    super.initState();
    AppToastController.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    AppToastController.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = AppToastController.instance.current;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(0, -0.12),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: offsetAnimation, child: child),
                    );
                  },
                  child: current == null
                      ? const SizedBox.shrink(key: ValueKey('app_toast_empty'))
                      : Align(
                          key: ValueKey(current.id),
                          alignment: Alignment.topCenter,
                          child: AppAlertCard(
                            message: current.message,
                            title: current.title,
                            type: current.type,
                            onClose: AppToastController.instance.dismissCurrent,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The reusable "rounded card" alert visual: icon + title + message + close
/// button. Shared by [AppToastHost] and any screen that wants to render the
/// same style inline (see login.dart).
class AppAlertCard extends StatelessWidget {
  final String message;
  final String title;
  final AppToastType type;
  final VoidCallback onClose;

  const AppAlertCard({
    super.key,
    required this.message,
    required this.title,
    required this.type,
    required this.onClose,
  });

  _AlertStyle _styleFor(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return const _AlertStyle(
          icon: Icons.check_circle_rounded,
          backgroundColor: Color(0xFFF0FDF4),
          borderColor: Color(0xFFBBF7D0),
          iconBackgroundColor: Color(0xFFDCFCE7),
          iconColor: Color(0xFF15803D),
          shadowColor: Color(0x1A16A34A),
        );
      case AppToastType.error:
        return const _AlertStyle(
          icon: Icons.error_rounded,
          backgroundColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFECACA),
          iconBackgroundColor: Color(0xFFFEE2E2),
          iconColor: Color(0xFFDC2626),
          shadowColor: Color(0x1ADC2626),
        );
      case AppToastType.info:
        return const _AlertStyle(
          icon: Icons.info_rounded,
          backgroundColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
          iconBackgroundColor: Color(0xFFDBEAFE),
          iconColor: Color(0xFF2563EB),
          shadowColor: Color(0x1A2563EB),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(type);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.borderColor),
        boxShadow: [
          BoxShadow(
            color: style.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: style.iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.captionSemiBold.copyWith(
                        color: const Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AppText.caption.copyWith(
                        color: const Color(0xFF4B5563),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: style.iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, color: style.iconColor, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertStyle {
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color shadowColor;

  const _AlertStyle({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.shadowColor,
  });
}
