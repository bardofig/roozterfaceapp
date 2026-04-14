// lib/screens/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:roozterfaceapp/screens/rooster_details_screen.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Identificador QR'),
        actions: [
          ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              final torchState = controller.value.torchState;
              return IconButton(
                icon: Icon(
                  torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: torchState == TorchState.on ? Colors.yellow : Colors.grey,
                ),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              final facing = controller.value.cameraDirection;
              return IconButton(
                icon: Icon(
                  facing == CameraFacing.front ? Icons.camera_front : Icons.camera_rear,
                ),
                onPressed: () => controller.switchCamera(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => isScanned = true);
                  _processQrCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Superposición visual (Overlay)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: const Text(
              'Apunta al código QR del gallo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processQrCode(String data) async {
    try {
      final parts = data.split('|');
      if (parts.length != 2) throw Exception("Formato QR inválido");

      final galleraId = parts[0];
      final roosterId = parts[1];

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final roosterService = RoosterService();
      final rooster = await roosterService.getRoosterById(galleraId, roosterId);

      if (!mounted) return;
      Navigator.pop(context); // Quitar el loader

      if (rooster != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => RoosterDetailsScreen(rooster: rooster),
          ),
        );
      } else {
        _showError("No se encontró el ejemplar en la gallera especificada.");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError("Error al procesar el código: $e");
    }
  }

  void _showError(String message) {
    setState(() => isScanned = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
