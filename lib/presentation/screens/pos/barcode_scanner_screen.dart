import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late MobileScannerController controller;
  bool isScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      formats: const [BarcodeFormat.all],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      setState(() => isScanned = true);
      
      // Stop scanner before pop to prevent memory leaks/crashes
      controller.stop().then((_) {
        if (mounted) Navigator.of(context).pop(code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scan Barcode Produk', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off, color: Colors.white),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_rear, color: Colors.white),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 60),
                    const SizedBox(height: 16),
                    Text('Scanner Error: ${error.errorCode}', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
          ),
          // Scanner Overlay Guide
          Container(
            decoration: ShapeDecoration(
              shape: _ScannerOverlayShape(
                borderColor: AppColors.primary,
                borderWidth: 3.0,
                overlayColor: Colors.black54,
                borderRadius: 12,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
          ),
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan barcode ke dalam area kotak',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double cutOutSize;

  const _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.overlayColor = const Color(0x88000000),
    this.borderRadius = 0,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..fillType = PathFillType.evenOdd;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final Path path = Path()..addRect(rect);
    return path..addPath(_getCutOutPath(rect), Offset.zero)..fillType = PathFillType.evenOdd;
  }

  Path _getCutOutPath(Rect rect) {
    final double left = (rect.width - cutOutSize) / 2;
    final double top = (rect.height - cutOutSize) / 2;
    final double right = left + cutOutSize;
    final double bottom = top + cutOutSize;
    return Path()
      ..addRRect(RRect.fromLTRBR(left, top, right, bottom, Radius.circular(borderRadius)));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    
    final cutoutPath = _getCutOutPath(rect);

    canvas.drawPath(
      Path()
        ..addRect(rect)
        ..addPath(cutoutPath, Offset.zero)
        ..fillType = PathFillType.evenOdd,
      backgroundPaint,
    );

    // Draw corners
    final double left = (rect.width - cutOutSize) / 2;
    final double top = (rect.height - cutOutSize) / 2;
    final double right = left + cutOutSize;
    final double bottom = top + cutOutSize;
    final double length = cutOutSize * 0.15;
    
    final path = Path();
    
    // Top left
    path.moveTo(left, top + length);
    path.lineTo(left, top);
    path.lineTo(left + length, top);
    
    // Top right
    path.moveTo(right - length, top);
    path.lineTo(right, top);
    path.lineTo(right, top + length);
    
    // Bottom right
    path.moveTo(right, bottom - length);
    path.lineTo(right, bottom);
    path.lineTo(right - length, bottom);
    
    // Bottom left
    path.moveTo(left + length, bottom);
    path.lineTo(left, bottom);
    path.lineTo(left, bottom - length);
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
