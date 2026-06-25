import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import 'no_internet_screen.dart';
import 'splash/splash_screen.dart';

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      context.read<ConnectivityProvider>().initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Refresh ban/user state every time app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().refreshUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        if (connectivity.isChecking) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!connectivity.hasInternet) {
          return const NoInternetScreen();
        }

        return const SplashScreen();
      },
    );
  }
}
