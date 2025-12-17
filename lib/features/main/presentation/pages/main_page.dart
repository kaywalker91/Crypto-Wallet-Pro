
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../nft/presentation/pages/nft_gallery_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../wallet_connect/presentation/pages/wallet_connect_page.dart';
import '../../../wallet_connect/presentation/providers/wallet_connect_provider.dart';
import '../../../wallet_connect/presentation/widgets/session_proposal_dialog.dart';
import '../../../wallet_connect/presentation/widgets/session_request_dialog.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

/// Main page with bottom navigation
/// Contains 4 tabs: Dashboard, NFTs, Connect, Settings
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;
  StreamSubscription? _proposalSubscription;
  StreamSubscription? _requestSubscription;

  final List<Widget> _pages = [
    const DashboardPage(),
    const NftGalleryPage(),
    const WalletConnectPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize WalletConnect listeners after building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupWalletConnectListeners();
    });
  }

  void _setupWalletConnectListeners() {
    final wcService = ref.read(walletConnectServiceProvider);
    
    _proposalSubscription = wcService.onSessionProposal.listen((event) {
      _showSessionProposalDialog(event);
    });

    _requestSubscription = wcService.onSessionRequest.listen((event) {
      _showSessionRequestDialog(event);
    });
  }

  Future<void> _showSessionProposalDialog(SessionProposalEvent event) async {
    final walletState = await ref.read(walletProvider.future);
    final wallet = walletState.wallet;
    
    if (wallet == null) return;
    final address = wallet.address;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionProposalDialog(
        proposal: event,
        availableAccounts: [address],
        onApprove: (accounts) async {
          Navigator.of(context).pop();
          final wcService = ref.read(walletConnectServiceProvider);
          
          final namespaces = {
            'eip155': Namespace(
              accounts: accounts.map((a) => 'eip155:1:$a').toList(), // Mainnet default
              methods: ['eth_sendTransaction', 'personal_sign', 'eth_signTypedData'],
              events: ['chainChanged', 'accountsChanged'],
            ),
          };
          
          await wcService.approveSession(id: event.id, namespaces: namespaces);
        },
        onReject: () async {
          Navigator.of(context).pop();
          final wcService = ref.read(walletConnectServiceProvider);
          await wcService.rejectSession(
            id: event.id,
            reason: Errors.getSdkError(Errors.USER_REJECTED),
          );
        },
      ),
    );
  }

  Future<void> _showSessionRequestDialog(SessionRequestEvent event) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionRequestDialog(
        request: event,
        onApprove: () async {
          Navigator.of(context).pop();
          // Logic for handling the request (e.g. signing) would go here
          // For now, we simulate approval with a hardcoded result or error to avoid blocking
          // In real implementation, we would use private key to sign
          debugPrint('Request approved (Simulated)');
        },
        onReject: () async {
          Navigator.of(context).pop();
          final wcService = ref.read(walletConnectServiceProvider);
          await wcService.rejectRequest(
            topic: event.topic,
            id: event.id,
            error: Errors.getSdkError(Errors.USER_REJECTED),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _proposalSubscription?.cancel();
    _requestSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.cardBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.account_balance_wallet,
                  label: 'Wallet',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.collections,
                  label: 'NFTs',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.link,
                  label: 'Connect',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom navigation item with gradient indicator
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) {
                if (isSelected) {
                  return AppColors.primaryGradient.createShader(bounds);
                }
                return const LinearGradient(
                  colors: [AppColors.textTertiary, AppColors.textTertiary],
                ).createShader(bounds);
              },
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

