import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../professional_snackbar.dart';

class MapPreviewWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? googleMapsUrl;

  const MapPreviewWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.googleMapsUrl,
  }) : super(key: key);

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

class _MapPreviewWidgetState extends State<MapPreviewWidget> {
  bool _useStaticMap = true;

  String _buildStaticMapUrl() {
    const apiKey = 'AIzaSyC7SmI0itbd_iqVlQiNIzHzCegK5lAbfLw';
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=${widget.latitude},${widget.longitude}'
        '&zoom=15'
        '&size=600x300'
        '&markers=color:red%7C${widget.latitude},${widget.longitude}'
        '&key=$apiKey';
  }

  Future<void> _launchDirections(BuildContext context) async {
    final lat = widget.latitude;
    final lng = widget.longitude;

    // Try platform-specific deep link first
    Uri? nativeUri;
    if (Platform.isIOS) {
      nativeUri = Uri.parse('maps://?saddr=&daddr=$lat,$lng&dirflg=d');
    } else if (Platform.isAndroid) {
      nativeUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    }

    if (nativeUri != null && await canLaunchUrl(nativeUri)) {
      await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback to web URL
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      // Show error snackbar
      if (context.mounted) {
        context.showErrorSnackBar('Could not open navigation app');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.map,
                  color: AppColorsEnhanced.brandBlue,
                  size: 24.r,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Installation Location',
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Map Image or Fallback
          if (_useStaticMap)
            InkWell(
              onTap: () => _launchDirections(context),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12.r),
                  bottomRight: Radius.circular(12.r),
                ),
                child: Stack(
                  children: [
                    // Static Map Image
                    Image.network(
                      _buildStaticMapUrl(),
                      height: 200.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200.h,
                          color: AppColorsEnhanced.backgroundSecondary,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColorsEnhanced.brandBlue,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // Switch to fallback mode
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _useStaticMap = false;
                            });
                          }
                        });
                        return Container(
                          height: 200.h,
                          color: AppColorsEnhanced.backgroundSecondary,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColorsEnhanced.brandBlue,
                            ),
                          ),
                        );
                      },
                    ),

                    // Tap hint overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 18.r,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Tap for directions',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Fallback: Location Card
            _buildLocationCard(context),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Coordinates Display
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColorsEnhanced.brandBlue,
                          size: 32.r,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Latitude',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.secondaryText,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs / 2),
                        Text(
                          widget.latitude.toStringAsFixed(6),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 60.h,
                      color: AppColorsEnhanced.border,
                    ),
                    Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColorsEnhanced.brandBlue,
                          size: 32.r,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Longitude',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.secondaryText,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs / 2),
                        Text(
                          widget.longitude.toStringAsFixed(6),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          // Get Directions Button
          InkWell(
            onTap: () => _launchDirections(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColorsEnhanced.brandBlue,
                    AppColorsEnhanced.brandBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColorsEnhanced.brandBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 20.r,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Get Directions',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
