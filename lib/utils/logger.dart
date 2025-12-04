import 'dart:developer' as developer;

class AppLogger {
  static void log(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    String logMessage = tag != null ? '[$tag] $message' : message;
    
    if (error != null) {
      developer.log(
        logMessage,
        name: 'AppLogger',
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      developer.log(
        logMessage,
        name: 'AppLogger',
      );
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    String logMessage = tag != null ? '[$tag] $message' : message;
    
    developer.log(
      logMessage,
      name: 'AppLogger',
      level: 2000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
 }

  static void warning(String message, {String? tag}) {
    String logMessage = tag != null ? '[$tag] $message' : 'WARNING: $message';
    
    developer.log(
      logMessage,
      name: 'AppLogger',
      level: 1500, // Warning level
    );
  }
}