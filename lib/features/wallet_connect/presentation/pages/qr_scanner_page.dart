import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dapp_info.dart';
import '../providers/wallet_connect_provider.dart';
import '../widgets/connection_request_sheet.dart';

/// QR Scanner page for WalletConnect pairing
class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;
  bool hasScanned = false;
  String? errorMessage;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // QR Scanner view
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: AppColors.primary,
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: MediaQuery.of(context).size.width * 0.7,
              overlayColor: Colors.black.withAlpha(179),
            ),
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Title
                    const Text(
                      'Scan QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Flash toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                        onPressed: () => controller?.toggleFlash(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Error message
                    if (errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withAlpha(77)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.error,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  errorMessage = null;
                                  hasScanned = false;
                                });
                                controller?.resumeCamera();
                              },
                            ),
                          ],
                        ),
                      ),
                    // Processing indicator
                    if (isProcessing)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(179),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Connecting...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(179),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.qr_code_rounded,
                              color: AppColors.primary,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Scan WalletConnect QR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Go to a dApp, click "Connect Wallet" and scan the QR code',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withAlpha(179),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Manual input button
                    TextButton.icon(
                      onPressed: _showManualInput,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Enter URI manually'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!hasScanned && scanData.code != null) {
        _processQrCode(scanData.code!);
      }
    });
  }

  Future<void> _processQrCode(String code) async {
    if (hasScanned || isProcessing) return;

    setState(() {
      hasScanned = true;
      isProcessing = true;
      errorMessage = null;
    });

    controller?.pauseCamera();

    // Check if it's a valid WalletConnect URI
    if (!code.startsWith('wc:')) {
      setState(() {
        isProcessing = false;
        errorMessage = 'Invalid QR code. Please scan a WalletConnect QR code.';
      });
      return;
    }

    // Simulate parsing the URI and getting dApp info
    // In real implementation, this would come from the WalletConnect SDK
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      isProcessing = false;
    });

    // Show connection request sheet
    final approved = await ConnectionRequestSheet.show(
      context,
      dapp: const DappInfo(
        name: 'New dApp Connection',
        url: 'dapp.example.com',
        description: 'A decentralized application wants to connect to your wallet.',
      ),
      chainName: 'Ethereum Mainnet',
      methods: ['eth_sendTransaction', 'personal_sign'],
    );

    if (approved == true) {
      // Pair with the dApp
      await ref.read(walletConnectProvider.notifier).pair(code);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully connected!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Reset scanner
      setState(() {
        hasScanned = false;
      });
      controller?.resumeCamera();
    }
  }

  void _showManualInput() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter WalletConnect URI',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste the WalletConnect URI from the dApp',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'wc:...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final uri = textController.text.trim();
                  if (uri.isNotEmpty) {
                    Navigator.pop(context);
                    _processQrCode(uri);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
