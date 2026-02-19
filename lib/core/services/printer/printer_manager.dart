import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'printer_interface.dart';
import 'printer_factory.dart';
import 'printer_type.dart';
import 'printer_status.dart';

/// Unified printer manager - single entry point for all print operations
///
/// This singleton provides:
/// - Automatic device detection
/// - User preference handling
/// - Printer instance management
/// - Easy access to current printer
///
/// Usage:
/// ```dart
/// final manager = PrinterManager();
/// await manager.initialize();
/// final printer = await manager.getPrinter();
/// await printer.printBinaryData(data);
/// ```
class PrinterManager {
  static final PrinterManager _instance = PrinterManager._internal();
  factory PrinterManager() => _instance;
  PrinterManager._internal();

  PrinterInterface? _currentPrinter;
  PrinterType? _preferredType;

  static const String _preferenceKey = 'printer_type_preference';

  /// Initialize printer with optional user preference
  ///
  /// This method:
  /// 1. Checks for user preference
  /// 2. Falls back to auto-detection if no preference
  /// 3. Creates and initializes the printer instance
  ///
  /// Returns true if initialization succeeded
  Future<bool> initialize({PrinterType? preferredType}) async {
    try {
      // Load user preference if not provided
      if (preferredType == null) {
        _preferredType = await _getUserPreference();
      } else {
        _preferredType = preferredType;
      }

      debugPrint('PrinterManager: Initializing with preference: $_preferredType');

      _currentPrinter = await PrinterFactory.getPrinter(
        forceType: _preferredType,
      );

      final success = await _currentPrinter!.initialize();

      if (success) {
        debugPrint('PrinterManager: Initialized successfully (${_currentPrinter!.printerType})');
      } else {
        debugPrint('PrinterManager: Initialization failed');
      }

      return success;
    } catch (e) {
      debugPrint('PrinterManager: Initialization error: $e');
      return false;
    }
  }

  /// Get current printer instance
  ///
  /// If not yet initialized, will initialize with user preference or auto-detection
  Future<PrinterInterface> getPrinter() async {
    if (_currentPrinter == null) {
      await initialize(preferredType: _preferredType);
    }
    return _currentPrinter!;
  }

  /// Get printer type of current instance
  Future<PrinterType> getPrinterType() async {
    final printer = await getPrinter();
    return printer.printerType;
  }

  /// Check if current device has Sunmi printer
  Future<bool> isSunmiDevice() async {
    final type = await getPrinterType();
    return type == PrinterType.sunmi;
  }

  /// Reset printer instance
  ///
  /// Useful when:
  /// - User changes printer type preference
  /// - Testing different printer types
  /// - Recovering from errors
  ///
  /// Parameters:
  /// - newPreferredType: Optional new printer type preference
  Future<void> reset({PrinterType? newPreferredType}) async {
    debugPrint('PrinterManager: Resetting printer instance');

    // Dispose current printer
    await _currentPrinter?.dispose();
    _currentPrinter = null;

    // Clear factory cache
    PrinterFactory.clearCache();

    // Re-initialize with new preference
    await initialize(preferredType: newPreferredType);
  }

  /// Get printer status stream
  ///
  /// Subscribe to this stream to receive real-time printer status updates
  Stream<PrinterStatus> get statusStream async* {
    final printer = await getPrinter();
    yield* printer.statusStream;
  }

  /// Get current printer status
  Future<PrinterStatus> getCurrentStatus() async {
    final printer = await getPrinter();
    return printer.currentStatus;
  }

  /// Get user's printer type preference from storage
  ///
  /// Returns null if no preference is set (use auto-detection)
  Future<PrinterType?> _getUserPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pref = prefs.getString(_preferenceKey);

      if (pref == null) return null;

      // Parse preference string
      return PrinterType.values.firstWhere(
        (e) => e.toString() == pref,
        orElse: () => PrinterType.bluetooth, // Default fallback
      );
    } catch (e) {
      debugPrint('PrinterManager: Error loading preference: $e');
      return null;
    }
  }

  /// Save user's printer type preference
  ///
  /// Parameters:
  /// - type: Printer type to save, or null to clear preference (use auto-detection)
  Future<void> setUserPreference(PrinterType? type) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (type == null) {
        await prefs.remove(_preferenceKey);
        debugPrint('PrinterManager: Cleared user preference');
      } else {
        await prefs.setString(_preferenceKey, type.toString());
        debugPrint('PrinterManager: Saved user preference: $type');
      }

      // Reset printer with new preference
      await reset(newPreferredType: type);
    } catch (e) {
      debugPrint('PrinterManager: Error saving preference: $e');
    }
  }

  /// Get current user preference (without loading from storage)
  PrinterType? get currentPreference => _preferredType;

  /// Check if printer is connected and ready
  Future<bool> isReady() async {
    try {
      final printer = await getPrinter();
      return printer.currentStatus.isConnected;
    } catch (e) {
      return false;
    }
  }

  /// Dispose all resources
  Future<void> dispose() async {
    await _currentPrinter?.dispose();
    _currentPrinter = null;
    PrinterFactory.clearCache();
  }
}
