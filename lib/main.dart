import 'package:workbyte_app/providers/connectivity_provider.dart';
import 'package:workbyte_app/screens/app_gate.dart';
import 'package:workbyte_app/screens/auth/login.dart';
import 'package:workbyte_app/screens/no_internet_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
import 'providers/notification_provider.dart';
import 'providers/saved_items_provider.dart';
import 'providers/dm_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/appeal_provider.dart';
import 'providers/report_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  GoogleFonts.config.allowRuntimeFetching = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  await NotificationService.initialize(navigatorKey: navigatorKey);
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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SavedItemsProvider()),
        ChangeNotifierProvider(create: (_) => DMProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => AppealProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WorkByte',
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        builder: (context, child) {
          return Consumer2<ConnectivityProvider, AuthProvider>(
            builder: (context, connectivity, auth, _) {
              if (auth.sessionExpired) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  auth.clearSessionExpired();
                  context.read<NotificationProvider>().clear();

                  scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your session has expired. Please log in again.',
                      ),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 4),
                    ),
                  );

                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                });
              }

              if (connectivity.isChecking) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  if (!connectivity.hasInternet) const NoInternetScreen(),
                ],
              );
            },
          );
        },
        home: const AppGate(),
      ),
    );
  }
}
