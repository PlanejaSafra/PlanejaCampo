import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class LogService {
  static void log(String message, {String? tag, bool isError = false}) {
    final logMessage = '[${tag ?? 'APP'}] $message';
    if (kDebugMode) {
      print(logMessage);
    }
    if (isError) {
      FirebaseCrashlytics.instance.log(logMessage);
    }
  }

  static void logError(dynamic error, StackTrace stackTrace, {String? tag}) {
    log('Error: $error', tag: tag, isError: true);
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}