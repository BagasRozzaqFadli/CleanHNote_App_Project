import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../models/team_analytics.dart';

/// Service for realtime analytics updates via Appwrite Realtime
class RealtimeAnalyticsService {
  static final RealtimeAnalyticsService _instance =
      RealtimeAnalyticsService._internal();
  factory RealtimeAnalyticsService() => _instance;
  RealtimeAnalyticsService._internal();

  late Client _client;
  late Realtime _realtime;
  RealtimeSubscription? _subscription;

  final StreamController<TeamAnalytics?> _analyticsController =
      StreamController<TeamAnalytics?>.broadcast();

  final StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();

  // Appwrite Configuration
  static const String _endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String _projectId = '6935585d000912ee1a86';
  static const String _databaseId = '693558df001f7968fabd';
  static const String _collectionId = 'team_analytics';

  bool _isInitialized = false;
  bool mounted = true;
  String? _currentTeamId;

  /// Initialize Appwrite Realtime client
  void initialize() {
    if (_isInitialized) return;

    _client = Client().setEndpoint(_endpoint).setProject(_projectId);
    _realtime = Realtime(_client);
    _isInitialized = true;

    print('✅ Realtime Analytics Service initialized');
  }

  /// Subscribe to team analytics updates
  Stream<TeamAnalytics?> subscribeToTeamAnalytics(String teamId) {
    if (!_isInitialized) {
      initialize();
    }

    // Unsubscribe from previous subscription if exists
    if (_subscription != null && _currentTeamId != teamId) {
      unsubscribe();
    }

    _currentTeamId = teamId;

    // Create channel for specific team document
    final channel =
        'databases.$_databaseId.collections.$_collectionId.documents.$teamId';

    try {
      _subscription = _realtime.subscribe([channel]);

      // Emit connecting status first
      _connectionController.add(ConnectionStatus.connecting);
      print('🔄 Subscribing to team analytics: $teamId');

      // Listen to connection status
      _subscription!.stream.listen(
        (response) {
          print('📡 Realtime event received: ${response.events}');

          // Update connection status to connected on first event
          _connectionController.add(ConnectionStatus.connected);

          // Parse and emit analytics data
          if (response.payload.isNotEmpty) {
            try {
              final analytics = TeamAnalytics.fromJson(response.payload);
              _analyticsController.add(analytics);
              print('✅ Analytics updated via realtime');
            } catch (e) {
              print('❌ Error parsing analytics: $e');
              // Don't change connection status for parsing errors
            }
          }
        },
        onError: (error) {
          print('❌ Realtime subscription error: $error');
          _connectionController.add(ConnectionStatus.error);

          // Try to reconnect after delay
          Future.delayed(const Duration(seconds: 5), () {
            if (_currentTeamId != null && mounted) {
              print('🔄 Attempting to reconnect...');
              subscribeToTeamAnalytics(_currentTeamId!);
            }
          });
        },
        onDone: () {
          print('⚠️ Realtime subscription ended');
          _connectionController.add(ConnectionStatus.disconnected);
        },
      );

      // Emit connected status after successful subscription
      // This ensures the UI shows connected even before first event
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_subscription != null && mounted) {
          _connectionController.add(ConnectionStatus.connected);
          print('✅ Realtime connection established');
        }
      });

      print('✅ Subscribed to team analytics: $teamId');
    } catch (e) {
      print('❌ Failed to subscribe: $e');
      _connectionController.add(ConnectionStatus.error);
    }

    return _analyticsController.stream;
  }

  /// Get connection status stream
  Stream<ConnectionStatus> get connectionStatus => _connectionController.stream;

  /// Unsubscribe from current subscription
  void unsubscribe() {
    if (_subscription != null) {
      _subscription!.close();
      _subscription = null;
      _currentTeamId = null;
      _connectionController.add(ConnectionStatus.disconnected);
      print('✅ Unsubscribed from analytics updates');
    }
  }

  /// Check if currently subscribed
  bool get isSubscribed => _subscription != null;

  /// Get current team ID
  String? get currentTeamId => _currentTeamId;

  /// Dispose service (cleanup)
  void dispose() {
    mounted = false;
    unsubscribe();
    _analyticsController.close();
    _connectionController.close();
    _isInitialized = false;
    print('✅ Realtime service disposed');
  }
}

/// Connection status enum
enum ConnectionStatus { disconnected, connecting, connected, error }

/// Extension for connection status UI
extension ConnectionStatusExtension on ConnectionStatus {
  String get label {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.error:
        return 'Connection Error';
    }
  }

  Color get color {
    switch (this) {
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ConnectionStatus.disconnected:
        return Icons.cloud_off;
      case ConnectionStatus.connecting:
        return Icons.cloud_queue;
      case ConnectionStatus.connected:
        return Icons.cloud_done;
      case ConnectionStatus.error:
        return Icons.error;
    }
  }
}

// For color import
