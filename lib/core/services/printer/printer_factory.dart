import 'package:flutter/foundation.dart';
import 'package:sunmi_printer_plugin/sunmi_printer_plugin.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'printer_interface.dart';
import 'printer_type.dart';
import 'bluetooth_printer_service.dart';
import 'sunmi_printer_service.dart';

/// Factory class for creating appropriate printer instances based on device type
/// Implements automatic device detection and caching for performance
class PrinterFactory {
  static PrinterType? _detectedType;
  static PrinterInterface? _cachedPrinter;
  static DateTime? _lastDetectionTime;
  static const _cacheValidityDuration = Duration(hours: 1);

  /// Get or create a printer instance
  ///
  /// Parameters:
  /// - forceType: Optional parameter to force a specific printer type
  ///              If null, will use automatic detection
  ///
  /// Returns the appropriate PrinterInterface implementation
  static Future<PrinterInterface> getPrinter({
    PrinterType? forceType,
  }) async {
    // Return cached if valid and no force type specified
    if (forceType == null &&
        _cachedPrinter != null &&
        _lastDetectionTime != null &&
        DateTime.now().difference(_lastDetectionTime!) < _cacheValidityDuration) {
      debugPrint('PrinterFactory: Returning cached printer (${_detectedType})');
      return _cachedPrinter!;
    }

    // Clear cache if forcing a different type
    if (forceType != null && forceType != _detectedType) {
      debugPrint('PrinterFactory: Forcing printer type: $forceType');
      clearCache();
    }

    // Use forced type or auto-detect
    final type = forceType ?? await detectPrinterType();

    _detectedType = type;
    _cachedPrinter = _createPrinter(type);
    _lastDetectionTime = DateTime.now();

    debugPrint('PrinterFactory: Created printer instance: $type');
    return _cachedPrinter!;
  }

  /// Detect if running on Sunmi device or regular Android
  ///
  /// Returns PrinterType.sunmi if device manufacturer is SUNMI and printer service is available
  /// Otherwise returns PrinterType.bluetooth
  static Future<PrinterType> detectPrinterType() async {
    try {
      debugPrint('PrinterFactory: Detecting printer type...');

      // Step 1: Check if device manufacturer is SUNMI
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toUpperCase();

      debugPrint('PrinterFactory: Device manufacturer: $manufacturer');
      debugPrint('PrinterFactory: Device model: ${androidInfo.model}');

      // Step 2: Only check for Sunmi printer if manufacturer is SUNMI
      if (manufacturer == 'SUNMI') {
        try {
          final isSunmi = await SunmiPrinter.bindingPrinter();

          if (isSunmi == true) {
            debugPrint('PrinterFactory: Sunmi printer detected and available');
            return PrinterType.sunmi;
          } else {
            debugPrint('PrinterFactory: SUNMI device but printer service unavailable');
          }
        } catch (e) {
          debugPrint('PrinterFactory: SUNMI device but printer binding failed: $e');
        }
      } else {
        debugPrint('PrinterFactory: Not a SUNMI device (manufacturer: $manufacturer)');
      }
    } catch (e) {
      debugPrint('PrinterFactory: Device detection error: $e');
    }

    // Default to Bluetooth for all non-SUNMI devices
    debugPrint('PrinterFactory: Defaulting to Bluetooth printer');
    return PrinterType.bluetooth;
  }

  /// Create a printer instance of the specified type
  static PrinterInterface _createPrinter(PrinterType type) {
    switch (type) {
      case PrinterType.sunmi:
        return SunmiPrinterService();
      case PrinterType.bluetooth:
        return BluetoothPrinterService();
    }
  }

  /// Clear cached printer instance
  /// Useful for testing or when user manually changes printer type preference
  static void clearCache() {
    debugPrint('PrinterFactory: Clearing cache');
    _cachedPrinter?.dispose();
    _cachedPrinter = null;
    _detectedType = null;
    _lastDetectionTime = null;
  }

  /// Get the last detected printer type without re-detection
  /// Returns null if detection hasn't been performed yet
  static PrinterType? get detectedType => _detectedType;

  /// Check if cache is valid
  static bool get isCacheValid {
    if (_cachedPrinter == null || _lastDetectionTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastDetectionTime!) < _cacheValidityDuration;
  }
}
