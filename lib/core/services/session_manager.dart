import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// A global session manager to handle session timeouts,
// auto-logout, and session restoration
class SessionManager {
  // Singleton instance
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // Configuration
  static const String _lastActivityKey = 'last_activity_timestamp';
  static const int _sessionTimeoutMinutes = 30; // Default session timeout

  // Session timer
  Timer? _sessionTimer;

  // Session expired callback
  VoidCallback? _onSessionExpired;

  // Current session timeout in minutes
  int _currentTimeoutMinutes = _sessionTimeoutMinutes;

  // Initialize the session manager
  void init({
    VoidCallback? onSessionExpired,
    int? sessionTimeoutMinutes,
  }) {
    _onSessionExpired = onSessionExpired;
    _currentTimeoutMinutes = sessionTimeoutMinutes ?? _sessionTimeoutMinutes;

    // Start the session timer
    _startSessionTimer();
  }

  // Record user activity to extend the session
  Future<void> recordUserActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastActivityKey, now);
  }

  // Start the session timer that checks for inactivity
  void _startSessionTimer() {
    // Cancel any existing timer
    _sessionTimer?.cancel();

    // Create a new timer that checks every minute
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkSessionValidity();
    });
  }

  // Check if the session is still valid based on last activity
  Future<void> _checkSessionValidity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt(_lastActivityKey);

    if (lastActivity == null) {
      // No activity recorded yet, record current time
      await recordUserActivity();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - lastActivity;
    final differenceInMinutes = difference / (1000 * 60);

    if (differenceInMinutes >= _currentTimeoutMinutes) {
      // Session has expired
      await _handleSessionExpired();
    }
  }

  // Handle session expiration
  Future<void> _handleSessionExpired() async {
    // Cancel the timer
    _sessionTimer?.cancel();

    // Clear the last activity
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);

    // Call the session expired callback
    if (_onSessionExpired != null) {
      _onSessionExpired!();
    }
  }

  // Manually logout and clear the session
  Future<void> logout() async {
    await _handleSessionExpired();
  }

  // Check if there's an active session
  Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt(_lastActivityKey);

    if (lastActivity == null) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - lastActivity;
    final differenceInMinutes = difference / (1000 * 60);

    return differenceInMinutes < _currentTimeoutMinutes;
  }

  // Update the session timeout duration
  void updateSessionTimeout(int timeoutMinutes) {
    _currentTimeoutMinutes = timeoutMinutes;
  }

  // Dispose of resources
  void dispose() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }
}

// Widget that detects user activity and updates the session
class UserActivityDetector extends StatefulWidget {
  final Widget child;

  const UserActivityDetector({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<UserActivityDetector> createState() => _UserActivityDetectorState();
}

class _UserActivityDetectorState extends State<UserActivityDetector> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => SessionManager().recordUserActivity(),
      onPointerMove: (_) => SessionManager().recordUserActivity(),
      onPointerUp: (_) => SessionManager().recordUserActivity(),
      child: widget.child,
    );
  }
}

// Session timeout dialog
class SessionTimeoutDialog extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onContinue;

  const SessionTimeoutDialog({
    Key? key,
    required this.onLogout,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Session Timeout'),
      content: const Text(
        'Your session is about to expire due to inactivity. '
            'Would you like to continue?',
      ),
      actions: [
        TextButton(
          onPressed: onLogout,
          child: const Text('LOGOUT'),
        ),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('CONTINUE'),
        ),
      ],
    );
  }
}

// Example of how to integrate the SessionManager in your app
class SessionAwareApp extends StatefulWidget {
  final Widget child;

  const SessionAwareApp({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<SessionAwareApp> createState() => _SessionAwareAppState();
}

class _SessionAwareAppState extends State<SessionAwareApp> {
  final SessionManager _sessionManager = SessionManager();
  Timer? _warningTimer;
  bool _showingWarning = false;

  @override
  void initState() {
    super.initState();

    // Initialize session manager
    _sessionManager.init(
      onSessionExpired: _handleSessionExpired,
      sessionTimeoutMinutes: 30, // 30 minutes
    );

    // Start warning timer (5 minutes before timeout)
    _startWarningTimer();
  }

  void _startWarningTimer() {
    _warningTimer?.cancel();
    _warningTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkWarningNeeded();
    });
  }

  Future<void> _checkWarningNeeded() async {
    if (_showingWarning) return;

    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('last_activity_timestamp');

    if (lastActivity == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - lastActivity;
    final differenceInMinutes = difference / (1000 * 60);

    // Show warning 5 minutes before timeout
    if (differenceInMinutes >= 25 && differenceInMinutes < 30) {
      _showTimeoutWarning();
    }
  }

  void _showTimeoutWarning() {
    if (_showingWarning) return;

    setState(() {
      _showingWarning = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SessionTimeoutDialog(
          onLogout: () {
            Navigator.of(dialogContext).pop();
            _handleSessionExpired();
          },
          onContinue: () {
            Navigator.of(dialogContext).pop();
            _sessionManager.recordUserActivity();
            setState(() {
              _showingWarning = false;
            });
          },
        );
      },
    ).then((_) {
      setState(() {
        _showingWarning = false;
      });
    });
  }

  void _handleSessionExpired() {
    // Navigate to login screen
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _warningTimer?.cancel();
    _sessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UserActivityDetector(
      child: widget.child,
    );
  }
}