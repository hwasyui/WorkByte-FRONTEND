import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart';
import 'providers/profile_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const WorkByteApp());
}

class WorkByteApp extends StatelessWidget {
  const WorkByteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WorkByte',
        home: const SplashScreen(),
      ),
    );
  }
}
