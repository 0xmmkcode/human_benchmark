import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLogger {
  AppLogger._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static void log(String message, [Map<String, Object?> extra = const {}]) {
    final String platform = kIsWeb ? 'web' : 'mobile';
    final String line =
        '[App][$platform] $message ${extra.isEmpty ? '' : extra.toString()}';
    // Print and send to developer log
    // ignore: avoid_print
    print(line);
    dev.log(message, name: 'App', error: null, stackTrace: null);
    _sendRemote('log', message, extra);
  }

  static void event(String name, [Map<String, Object?> props = const {}]) {
    final String platform = kIsWeb ? 'web' : 'mobile';
    final String msg = 'Event: $name';
    final Map<String, Object?> extra = {'platform': platform, ...props};
    // ignore: avoid_print
    print('[App][$platform] $msg $extra');
    dev.log(msg, name: 'Event', error: null, stackTrace: null);
    _sendRemote('event', name, extra);
  }

  static void error(
    String where,
    Object error, [
    StackTrace? stack,
    Map<String, Object?> extra = const {},
  ]) {
    final String platform = kIsWeb ? 'web' : 'mobile';
    // ignore: avoid_print
    print(
      '[App][$platform][Error][$where] $error ${extra.isEmpty ? '' : extra.toString()}',
    );
    dev.log('Error in $where', name: 'Error', error: error, stackTrace: stack);
    _sendRemote('error', where, {
      'error': error.toString(),
      if (stack != null) 'stack': stack.toString(),
      ...extra,
    });
  }

  static Future<void> _sendRemote(
    String type,
    String message,
    Map<String, Object?> data,
  ) async {
    if (Firebase.apps.isEmpty) return; // no-ops if Firebase not configured
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      await _firestore.collection('app_logs').add({
        'type': type,
        'message': message,
        'data': data,
        'userId': user?.uid,
        'platform': kIsWeb ? 'web' : 'mobile',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Swallow logging errors
    }
  }
}

class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    AppLogger.event('route.push', {
      'route': route.settings.name ?? route.settings.toString(),
      'previous':
          previousRoute?.settings.name ?? previousRoute?.settings.toString(),
    });
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    AppLogger.event('route.replace', {
      'new': newRoute?.settings.name ?? newRoute?.settings.toString(),
      'old': oldRoute?.settings.name ?? oldRoute?.settings.toString(),
    });
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    AppLogger.event('route.pop', {
      'route': route.settings.name ?? route.settings.toString(),
      'previous':
          previousRoute?.settings.name ?? previousRoute?.settings.toString(),
    });
    super.didPop(route, previousRoute);
  }
}
