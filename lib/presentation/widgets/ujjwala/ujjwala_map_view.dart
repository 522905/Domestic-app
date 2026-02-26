import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../domain/entities/ujjwala/ujjwala_installation.dart';
import 'installation_detail_popup.dart';

class UjjwalaMapView extends StatefulWidget {
  final List<UjjwalaInstallation> installations;
  final Function(UjjwalaInstallation)? onMarkerTap;

  const UjjwalaMapView({
    Key? key,
    required this.installations,
    this.onMarkerTap,
  }) : super(key: key);

  @override
  State<UjjwalaMapView> createState() => _UjjwalaMapViewState();
}

class _UjjwalaMapViewState extends State<UjjwalaMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _center;
  LatLng? _currentLocation;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permissions denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permissions permanently denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      print('📍 Current location: ${_currentLocation}');
    } catch (e) {
      print('⚠️ Error getting current location: $e');
    }
  }

  @override
  void didUpdateWidget(UjjwalaMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.installations != widget.installations) {
      _initializeMarkers();
    }
  }

  void _initializeMarkers() {
    final markers = <Marker>{};
    final positions = <LatLng>[];

    print('📍 UjjwalaMapView: Initializing markers for ${widget.installations.length} installations');

    for (final installation in widget.installations) {
      print('📍 Installation ${installation.id}: lat=${installation.latitude}, lng=${installation.longitude}');

      if (installation.latitude != null &&
          installation.longitude != null &&
          installation.latitude != 0.0 &&
          installation.longitude != 0.0) {
        final position = LatLng(installation.latitude!, installation.longitude!);
        positions.add(position);

        markers.add(
          Marker(
            markerId: MarkerId('installation_${installation.id}'),
            position: position,
            infoWindow: InfoWindow(
              title: installation.consumerName,
              snippet: installation.applicationNumber,
            ),
            onTap: () => _showInstallationDetail(installation),
          ),
        );
      }
    }

    print('📍 Created ${markers.length} markers from ${widget.installations.length} installations');

    setState(() {
      _markers = markers;
      if (positions.isNotEmpty) {
        // Calculate center of all positions
        double avgLat = positions.map((p) => p.latitude).reduce((a, b) => a + b) / positions.length;
        double avgLng = positions.map((p) => p.longitude).reduce((a, b) => a + b) / positions.length;
        _center = LatLng(avgLat, avgLng);
        print('📍 Map center: $_center');
      } else {
        // Default center (India)
        _center = const LatLng(28.6139, 77.2090);
        print('📍 No valid coordinates, using default center: $_center');
      }
    });
  }

  void _centerMap() {
    if (_mapController == null || _center == null || !mounted) return;

    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_center!),
      );
    } catch (e) {
      print('⚠️ Error centering map: $e');
    }
  }

  void _goToCurrentLocation() {
    if (_mapController == null || _currentLocation == null || !mounted) return;

    try {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: 14.0,
          ),
        ),
      );
    } catch (e) {
      print('⚠️ Error going to current location: $e');
    }
  }

  void _fitAllMarkers() {
    if (_mapController == null || _markers.isEmpty || !mounted) return;

    try {
      final positions = _markers.map((m) => m.position).toList();

      if (positions.isEmpty) return;

      // Calculate bounds
      double minLat = positions.first.latitude;
      double maxLat = positions.first.latitude;
      double minLng = positions.first.longitude;
      double maxLng = positions.first.longitude;

      for (final pos in positions) {
        if (pos.latitude < minLat) minLat = pos.latitude;
        if (pos.latitude > maxLat) maxLat = pos.latitude;
        if (pos.longitude < minLng) minLng = pos.longitude;
        if (pos.longitude > maxLng) maxLng = pos.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } catch (e) {
      print('⚠️ Error fitting markers: $e');
    }
  }

  void _showInstallationDetail(UjjwalaInstallation installation) {
    InstallationDetailPopup.show(
      context,
      installation: installation,
      onViewDetails: () {
        if (widget.onMarkerTap != null) {
          widget.onMarkerTap!(installation);
        }
      },
      onSubmit: () {
        if (widget.onMarkerTap != null) {
          widget.onMarkerTap!(installation);
        }
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            setState(() {
              _isMapReady = true;
            });
            // Fit all markers after map is created
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _mapController != null) {
                _fitAllMarkers();
              }
            });
          },
          initialCameraPosition: CameraPosition(
            target: _center ?? const LatLng(28.6139, 77.2090),
            zoom: 12.0,
          ),
          markers: _markers,
          myLocationEnabled: true,  // Show blue dot for current location
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapType: MapType.normal,
          // Enable all gestures for smooth interaction
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          // Set zoom limits
          minMaxZoomPreference: const MinMaxZoomPreference(5.0, 20.0),
          // Enable gesture recognizers for multi-touch
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          // Performance optimizations
          liteModeEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          buildingsEnabled: true,
          indoorViewEnabled: false,
          trafficEnabled: false,
        ),
        // Loading indicator while map initializes
        if (!_isMapReady)
          Container(
            color: Colors.white.withOpacity(0.9),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColorsEnhanced.brandBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading map...',
                    style: TextStyle(
                      color: AppColorsEnhanced.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Center all markers button
        Positioned(
          right: 16,
          bottom: 160,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _fitAllMarkers,
            child: Icon(
              Icons.center_focus_strong,
              color: AppColorsEnhanced.brandBlue,
            ),
          ),
        ),
        // Go to current location button
        Positioned(
          right: 16,
          bottom: 100,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _goToCurrentLocation,
            child: Icon(
              Icons.my_location,
              color: AppColorsEnhanced.brandBlue,
            ),
          ),
        ),
        // Info overlay
        if (_markers.isEmpty && _isMapReady)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 48,
                    color: AppColorsEnhanced.secondaryText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No installations with location data',
                    style: TextStyle(
                      color: AppColorsEnhanced.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total installations: ${widget.installations.length}',
                    style: TextStyle(
                      color: AppColorsEnhanced.secondaryText,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Installations with valid coordinates: 0',
                    style: TextStyle(
                      color: AppColorsEnhanced.secondaryText,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The API response does not include latitude/longitude fields or they are null/zero.',
                    style: TextStyle(
                      color: AppColorsEnhanced.secondaryText,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
