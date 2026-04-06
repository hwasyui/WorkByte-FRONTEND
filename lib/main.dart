import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const WorkByteApp());
}

class WorkByteApp extends StatelessWidget {
  const WorkByteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WorkByte',
        home: const SplashScreen(),
      ),
    );
  }
}
