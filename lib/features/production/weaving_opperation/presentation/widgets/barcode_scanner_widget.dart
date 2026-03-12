import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// =============================================================================
// WIDGET: SIMPLE BARCODE SCANNER (Full-screen)
// =============================================================================

/// Màn hình quét barcode toàn màn hình.
/// Trả về [String] rawValue của barcode đầu tiên được quét thành công
/// thông qua [Navigator.pop].
class SimpleBarcodeScanner extends StatefulWidget {
  const SimpleBarcodeScanner({super.key});

  @override
  State<SimpleBarcodeScanner> createState() => _SimpleBarcodeScannerState();
}

class _SimpleBarcodeScannerState extends State<SimpleBarcodeScanner> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    autoStart: false,
  );

  bool _isScanned = false;
  bool _isCameraStarted = false;

  Future<void> _startCamera() async {
    try {
      await controller.start();
      if (mounted) setState(() => _isCameraStarted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không mở được Camera: $e')));
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Quét mã Barcode')),
      body: Stack(
        children: [
          if (!_isCameraStarted)
            Center(
                child: ElevatedButton.icon(
                    onPressed: _startCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Bấm để mở Camera')))
          else ...[
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (_isScanned) return;
                for (final barcode in capture.barcodes) {
                  if (barcode.rawValue != null) {
                    setState(() => _isScanned = true);
                    Navigator.pop(context, barcode.rawValue);
                    break;
                  }
                }
              },
            ),
            CustomPaint(
                painter: ScannerOverlayPainter(),
                child: const SizedBox.expand()),
            const Center(
                child: Text(
              'Đưa mã vạch vào ô vuông',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
            )),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// PAINTER: Scanner overlay (khung vuông + góc trắng)
// =============================================================================

/// Vẽ lớp phủ tối với khung quét hình chữ nhật bo góc và 4 góc trắng.
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanWindowSize = size.width * 0.7;
    final Rect scanWindowRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: scanWindowSize,
        height: scanWindowSize);

    // Lớp phủ tối
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
          RRect.fromRectAndRadius(scanWindowRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
        backgroundPath,
        Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..style = PaintingStyle.fill);

    // Các góc trắng
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    const double cl = 30.0;

    canvas.drawLine(scanWindowRect.topLeft,
        scanWindowRect.topLeft + const Offset(cl, 0), borderPaint);
    canvas.drawLine(scanWindowRect.topLeft,
        scanWindowRect.topLeft + const Offset(0, cl), borderPaint);

    canvas.drawLine(scanWindowRect.topRight,
        scanWindowRect.topRight + const Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanWindowRect.topRight,
        scanWindowRect.topRight + const Offset(0, cl), borderPaint);

    canvas.drawLine(scanWindowRect.bottomLeft,
        scanWindowRect.bottomLeft + const Offset(cl, 0), borderPaint);
    canvas.drawLine(scanWindowRect.bottomLeft,
        scanWindowRect.bottomLeft + const Offset(0, -cl), borderPaint);

    canvas.drawLine(scanWindowRect.bottomRight,
        scanWindowRect.bottomRight + const Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanWindowRect.bottomRight,
        scanWindowRect.bottomRight + const Offset(0, -cl), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
