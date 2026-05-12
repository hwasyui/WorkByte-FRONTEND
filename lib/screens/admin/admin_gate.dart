import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'admin_login_screen.dart';
import 'admin_shell.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isAuthenticated) {
          return const AdminShell();
        }
        return const AdminLoginScreen();
      },
    );
  }
}
