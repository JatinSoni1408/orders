part of '../main.dart';

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage({required this.title});

  final String title;

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  late final MobileScannerController _scannerController;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final scanSize = size.shortestSide * 0.72;
          final left = (size.width - scanSize) / 2;
          final top = (size.height - scanSize) / 2;
          final scanWindow = Rect.fromLTWH(left, top, scanSize, scanSize);

          return Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (capture) {
                  if (_found || capture.barcodes.isEmpty) {
                    return;
                  }
                  final value = capture.barcodes.first.rawValue?.trim() ?? '';
                  if (value.isEmpty) {
                    return;
                  }
                  _found = true;
                  Navigator.of(context).pop(value);
                },
              ),
              IgnorePointer(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _QrScannerOverlayPainter(scanWindow: scanWindow),
                      ),
                    ),
                    Positioned.fromRect(
                      rect: scanWindow,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QrScannerOverlayPainter extends CustomPainter {
  _QrScannerOverlayPainter({required this.scanWindow});

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withAlpha(150);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectXY(scanWindow, 16, 16))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlay);
  }

  @override
  bool shouldRepaint(covariant _QrScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}
