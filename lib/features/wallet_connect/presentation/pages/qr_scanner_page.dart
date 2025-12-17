
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/wallet_connect_provider.dart';

class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: AppColors.primary,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
          if (isScanned)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (isScanned) return;
      if (scanData.code == null) return;

      setState(() {
        isScanned = true;
      });

      try {
        final uri = scanData.code!;
        debugPrint('Scanned URI: $uri');
        
        // Pair with WalletConnect
        final wcService = ref.read(walletConnectServiceProvider);
        await wcService.pair(uri);
        
        if (mounted) {
          context.pop(); // Go back after successful pairing initiation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connecting to dApp...')),
          );
        }
      } catch (e) {
        debugPrint('Pairing failed: $e');
        if (mounted) {
           setState(() {
            isScanned = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pairing failed: $e')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
