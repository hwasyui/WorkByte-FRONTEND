import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/job_post_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/proposal_provider.dart';
import 'providers/proposal_file_provider.dart';
import 'providers/contract_provider.dart';
import 'providers/contract_submission_provider.dart';
import 'providers/contract_message_provider.dart';
import 'providers/review_provider.dart';
import 'providers/skill_provider.dart';
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
        ChangeNotifierProvider(create: (_) => JobPostProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => SkillProvider()),
        ChangeNotifierProvider(create: (_) => ProposalProvider()),
        ChangeNotifierProvider(create: (_) => ProposalFileProvider()),
        ChangeNotifierProvider(create: (_) => ContractProvider()),
        ChangeNotifierProvider(create: (_) => ContractSubmissionProvider()),
        ChangeNotifierProvider(create: (_) => ContractMessageProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WorkByte',
        home: const SplashScreen(),
      ),
    );
  }
}
