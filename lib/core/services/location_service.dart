import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/ujjwala/ujjwala_location.dart';

class LocationService {
  /// Fetches the current GPS location with high accuracy
  /// Returns UjjwalaLocation with latitude, longitude, accuracy, and timestamp
  /// Throws LocationServiceException if location cannot be obtained
  Future<UjjwalaLocation> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceException(
          'Location services are disabled. Please enable location services in device settings.',
        );
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationServiceException(
            'Location permission denied. Please grant location permission to use this feature.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationServiceException(
          'Location permission permanently denied. Please enable location permission in app settings.',
        );
      }

      // Fetch current position with high accuracy and 10 second timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return UjjwalaLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp ?? DateTime.now(),
      );
    } on TimeoutException {
      throw LocationServiceException(
        'Location request timed out. Please try again.',
      );
    } on LocationServiceException {
      rethrow;
    } catch (e) {
      throw LocationServiceException(
        'Failed to get location: ${e.toString()}',
      );
    }
  }

  /// Checks if location permission is granted
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Opens app settings for the user to manually enable location permission
  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
  }
}

class LocationServiceException implements Exception {
  final String message;

  LocationServiceException(this.message);

  @override
  String toString() => message;
}
