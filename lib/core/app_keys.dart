import 'package:flutter/material.dart';

/// Global navigator/scaffold-messenger keys shared across the app so code
/// outside the widget tree (FCM foreground handlers, background callbacks)
/// can navigate or show a SnackBar without needing a BuildContext of its own.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
