import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'screens/free_dashboard_screen.dart';
import 'screens/premium_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'utils/logger.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/team_provider.dart';
import 'services/notification_scheduler.dart';
import 'services/notification_checker.dart';
import 'services/notification_background_worker.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.log('Starting application', tag: 'Main');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.log('Firebase initialized successfully', tag: 'Main');

    // Initialize notification scheduler
    await NotificationScheduler.initialize();
    AppLogger.log('Notification scheduler initialized', tag: 'Main');

    // Initialize WorkManager for background notifications
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode:
            true, // Enabled for testing, user can see notifications in console
      );
      // Register periodic task (runs every 15 mins)
      await Workmanager().registerPeriodicTask(
        "bg_notification_check",
        "check_notifications",
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType:
              NetworkType.connected, // Needs internet to check Firestore
        ),
      );
      AppLogger.log('WorkManager initialized and task registered', tag: 'Main');
    } catch (e) {
      AppLogger.error('Failed to init WorkManager: $e', error: e);
    }

    // Start notification checker (polls every 60s) for foreground
    NotificationChecker().start();
    AppLogger.log('Notification checker started', tag: 'Main');
  } catch (e, stack) {
    AppLogger.error(
      'Firebase initialization error: $e',
      error: e,
      stackTrace: stack,
    );
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.log('Building MyApp', tag: 'Main');
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        StreamProvider(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CleanHNote',
        theme: AppTheme.blueTheme,
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.log('Building AuthWrapper', tag: 'AuthWrapper');
    final firebaseUser = context.watch<User?>();
    AppLogger.log(
      'Current user: ${firebaseUser?.uid ?? "null"}',
      tag: 'AuthWrapper',
    );

    if (firebaseUser == null) {
      return const LoginScreen();
    }

    // Fetch user data from Firestore to determine role
    return FutureBuilder<UserModel?>(
      future: context.read<DatabaseService>().getUser(firebaseUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading user data'),
                  ElevatedButton(
                    onPressed: () async {
                      await context.read<AuthService>().signOut();
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data!;
        AppLogger.log('User role: ${user.role}', tag: 'AuthWrapper');

        // Route based on role
        switch (user.role) {
          case 'admin':
            return const AdminDashboardScreen();
          case 'premium':
            return const PremiumDashboardScreen();
          case 'free':
          default:
            return const FreeDashboardScreen();
        }
      },
    );
  }
}
