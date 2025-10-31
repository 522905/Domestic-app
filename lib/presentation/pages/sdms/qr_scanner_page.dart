// lib/presentation/pages/sdms/qr_scanner_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:math' show pi;

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  String? result;
  bool flashOn = false;
  bool _screenOpened = false;

  @override
  void initState() {
    super.initState();
    // Start scanning when page opens
    cameraController.start();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              flashOn ? Icons.flash_off : Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: () async {
              await cameraController.toggleTorch();
              setState(() {
                flashOn = !flashOn;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    if (!_screenOpened && result == null) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? code = barcodes.first.rawValue;
                        if (code != null && code.isNotEmpty) {
                          setState(() {
                            result = code;
                            _screenOpened = true;
                          });
                          cameraController.stop();
                        }
                      }
                    }
                  },
                ),
                // Custom overlay
                Center(
                  child: Container(
                    width: 250.w,
                    height: 250.w,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.transparent,
                        width: 0,
                      ),
                    ),
                    child: CustomPaint(
                      painter: ScannerOverlayPainter(
                        borderColor: const Color(0xFF0E5CA8),
                        borderWidth: 10,
                        borderLength: 30,
                        borderRadius: 10,
                      ),
                    ),
                  ),
                ),
                // Dark overlay around scanner area
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 250.w,
                          height: 250.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(5.w),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (result != null) ...[
                    Text(
                      'Scanned Result:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        result!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(result),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E5CA8),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: const Text('Use This Order ID'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                result = null;
                                _screenOpened = false;
                              });
                              cameraController.start();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0E5CA8),
                              side: const BorderSide(color: Color(0xFF0E5CA8)),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: const Text('Scan Again'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Icon(
                      Icons.qr_code_scanner,
                      size: 48.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Position QR code within the frame',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Make sure the QR code is clear and well-lit',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.borderLength,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final double width = size.width;
    final double height = size.height;

    // Top left corner
    canvas.drawLine(
      Offset(0, borderLength),
      Offset(0, borderRadius),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, 0, borderRadius * 2, borderRadius * 2),
      -pi,
      pi / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(borderRadius, 0),
      Offset(borderLength, 0),
      paint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(width - borderLength, 0),
      Offset(width - borderRadius, 0),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
          width - borderRadius * 2, 0, borderRadius * 2, borderRadius * 2),
      -pi / 2,
      pi / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(width, borderRadius),
      Offset(width, borderLength),
      paint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(width, height - borderLength),
      Offset(width, height - borderRadius),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(width - borderRadius * 2, height - borderRadius * 2,
          borderRadius * 2, borderRadius * 2),
      0,
      pi / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(width - borderRadius, height),
      Offset(width - borderLength, height),
      paint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(borderLength, height),
      Offset(borderRadius, height),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
          0, height - borderRadius * 2, borderRadius * 2, borderRadius * 2),
      pi / 2,
      pi / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(0, height - borderRadius),
      Offset(0, height - borderLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}