import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'screens/free_dashboard_screen.dart';
import 'screens/premium_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'utils/logger.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/team_provider.dart';
import 'services/notification_scheduler.dart';
import 'services/notification_checker.dart';
import 'services/notification_background_worker.dart';
import 'services/appwrite_service.dart';
import 'services/premium_downgrade_service.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.log('Starting application', tag: 'Main');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.log('Firebase initialized successfully', tag: 'Main');

    // Initialize Appwrite service for photo storage
    AppwriteService().initialize();
    AppLogger.log('Appwrite service initialized', tag: 'Main');

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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasCheckedDowngrade = false;

  Future<void> _checkPremiumDowngrade(String uid) async {
    if (_hasCheckedDowngrade) return;
    _hasCheckedDowngrade = true;

    try {
      final downgradeService = PremiumDowngradeService();
      final wasDowngraded = await downgradeService.checkAndApplyDowngrade(uid);

      if (wasDowngraded && mounted) {
        // Show notification to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ Your premium has expired. Features are now limited to Free plan.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Error checking premium downgrade: $e');
    }
  }

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

    // Listen to user data changes in real-time for automatic dashboard switching
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
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

        final user = UserModel.fromFirestore(snapshot.data!);
        AppLogger.log('User role: ${user.role}', tag: 'AuthWrapper');

        // Check for premium downgrade on app startup
        _checkPremiumDowngrade(firebaseUser.uid);

        // Route based on role (will automatically update when role changes)
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
