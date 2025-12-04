import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isGoogleSignInInitialized = false;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Initialize Google Sign In (call this before using Google Sign In)
  Future<void> initializeGoogleSignIn() async {
    AppLogger.log('Initializing Google Sign In', tag: 'AuthService');
    if (!_isGoogleSignInInitialized) {
      try {
        await _googleSignIn.initialize();
        _isGoogleSignInInitialized = true;
        AppLogger.log(
          'Google Sign In initialized successfully',
          tag: 'AuthService',
        );
      } catch (e, stack) {
        AppLogger.error(
          'Error initializing Google Sign In: $e',
          tag: 'AuthService',
          error: e,
          stackTrace: stack,
        );
      }
    } else {
      AppLogger.log('Google Sign In already initialized', tag: 'AuthService');
    }
  }

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle() async {
    AppLogger.log('Starting Google Sign In', tag: 'AuthService');
    try {
      // Ensure Google Sign In is initialized
      await initializeGoogleSignIn();

      // Authenticate the user
      AppLogger.log('Authenticating Google user', tag: 'AuthService');
      final GoogleSignInAccount googleUser = await _googleSignIn
          .authenticate();

      // Get authentication tokens (synchronous in version 7.x)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create Firebase credential with the ID token
      // Note: In version 7.x, accessToken is obtained separately via authorizationClient
      // For Firebase authentication, idToken is sufficient
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      AppLogger.log('Signing in with Firebase credential', tag: 'AuthService');
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Create user document if it doesn't exist
      try {
        final userDoc = _firestore
            .collection('users')
            .doc(userCredential.user!.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          final tenantId = _generateTenantId();
          AppLogger.log(
            'Creating new user document for Google sign in with tenantId: $tenantId',
            tag: 'AuthService',
          );
          await userDoc.set({
            'email': userCredential.user!.email,
            'role': 'free',
            'tenantId': tenantId,
            'currentTeamId': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          AppLogger.log(
            'User document already exists for Google sign in',
            tag: 'AuthService',
          );
        }
      } catch (e, stack) {
        AppLogger.error(
          'Error creating user document during Google sign in: $e',
          tag: 'AuthService',
          error: e,
          stackTrace: stack,
        );
      }

      AppLogger.log('Google Sign In successful', tag: 'AuthService');
      return userCredential;
    } catch (e, stack) {
      AppLogger.error(
        "Error signing in with Google: $e",
        tag: "AuthService",
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  // Sign In
  Future<UserCredential?> signIn(String email, String password) async {
    AppLogger.log('Starting sign in for email: $email', tag: 'AuthService');
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      AppLogger.log('Sign in successful for email: $email', tag: 'AuthService');
      return result;
    } catch (e, stack) {
      AppLogger.error(
        "Sign in failed for email $email: $e",
        tag: "AuthService",
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // Sign Up
  Future<UserCredential?> signUp(String email, String password) async {
    AppLogger.log('Starting sign up for email: $email', tag: 'AuthService');
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      AppLogger.log('Sign up successful for email: $email', tag: 'AuthService');

      // Generate unique tenant ID for admin search
      final tenantId = _generateTenantId();

      // Create user document in Firestore with default role 'free' and tenant ID
      try {
        AppLogger.log(
          'Creating user document for email: $email with tenantId: $tenantId',
          tag: 'AuthService',
        );
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'role': 'free', // Default to free plan
          'tenantId': tenantId,
          'currentTeamId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e, stack) {
        AppLogger.error(
          'Error creating user document: $e',
          tag: 'AuthService',
          error: e,
          stackTrace: stack,
        );
      }

      return result;
    } catch (e, stack) {
      AppLogger.error(
        "Sign up failed for email $email: $e",
        tag: "AuthService",
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // Generate random 6-character tenant ID
  String _generateTenantId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';
    var seed = random;

    for (var i = 0; i < 6; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      result += chars[seed % chars.length];
    }

    return result;
  }

  // Sign Out
  Future<void> signOut() async {
    AppLogger.log('Starting sign out', tag: 'AuthService');
    try {
      await _auth.signOut();
      AppLogger.log('Sign out successful', tag: 'AuthService');
    } catch (e, stack) {
      AppLogger.error(
        'Error signing out: $e',
        tag: 'AuthService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  // Get current user role
  Future<String?> getUserRole() async {
    AppLogger.log('Getting current user role', tag: 'AuthService');
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        AppLogger.log('Current user ID: ${user.uid}', tag: 'AuthService');
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          String? role = doc.get('role') as String?;
          AppLogger.log('User role: $role', tag: 'AuthService');
          return role;
        } else {
          AppLogger.log('User document does not exist', tag: 'AuthService');
        }
      } else {
        AppLogger.log('No current user', tag: 'AuthService');
      }
    } catch (e, stack) {
      AppLogger.error(
        'Error getting user role: $e',
        tag: 'AuthService',
        error: e,
        stackTrace: stack,
      );
    }
    return null;
  }
}
