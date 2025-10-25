import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../data/services/p2p_connection_manager.dart';
import '../providers/p2p_providers.dart' show
  p2pConnectionNotifierProvider,
  p2pPeersProvider,
  P2PNotifierState,
  P2PConnectionMode;

// Type alias for consistency with old code
typedef P2PConnectionState = P2PNotifierState;

/// P2P Peers Bottom Sheet
/// Shows discovered and connected peers for WiFi Direct (Android) or Multipeer (iOS)
class P2PPeersSheet extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const P2PPeersSheet({
    super.key,
    required this.userId,
    required this.userName,
  });

  /// Show the P2P peers sheet
  static void show(
    BuildContext context, {
    required String userId,
    required String userName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => P2PPeersSheet(
        userId: userId,
        userName: userName,
      ),
    );
  }

  @override
  ConsumerState<P2PPeersSheet> createState() => _P2PPeersSheetState();
}

class _P2PPeersSheetState extends ConsumerState<P2PPeersSheet> {
  @override
  void initState() {
    super.initState();
    _initializeP2P();
  }

  Future<void> _initializeP2P() async {
    try {
      debugPrint('Initializing P2P...');

      final notifier = ref.read(p2pConnectionNotifierProvider.notifier);
      await notifier.initialize(
        userId: widget.userId,
        userName: widget.userName,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('P2P initialization timed out');
        },
      );

      // Check if initialization succeeded
      final state = ref.read(p2pConnectionNotifierProvider);
      if (state.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? 'Failed to initialize P2P'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _initializeP2P,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ P2P initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('P2P initialization failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _initializeP2P,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(p2pConnectionNotifierProvider);
    final peersAsync = ref.watch(p2pPeersProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(state),
          const SizedBox(height: AppTheme.spacingMd),

          // Show error if initialization failed
          if (state.hasError) ...[
            Expanded(
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        state.errorMessage ?? 'Initialization failed',
                        style: TextStyle(color: Colors.red.shade900, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      ElevatedButton.icon(
                        onPressed: _initializeP2P,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Initialization'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingLg,
                            vertical: AppTheme.spacingMd,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (!state.isInitialized) ...[
            // Show loading during initialization
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppTheme.spacingMd),
                    Text('Initializing P2P connection...'),
                    SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'This may take a few seconds',
                      style: TextStyle(color: AppTheme.neutral400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Normal UI when initialized
            _buildModeSelector(state),
            const SizedBox(height: AppTheme.spacingMd),

            _buildStatistics(state),
            const SizedBox(height: AppTheme.spacingMd),

            Expanded(
              child: peersAsync.when(
                data: (peers) => _buildPeersList(peers, state),
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppTheme.spacingMd),
                      Text('Loading peers...'),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: AppTheme.spacingMd),
                      const Text(
                        'Error loading peers',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        error.toString(),
                        style: const TextStyle(color: AppTheme.neutral400, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(P2PConnectionState state) {
    final transportName = state.transportType == P2PTransportType.wifiDirect
        ? 'WiFi Direct'
        : state.transportType == P2PTransportType.multipeer
            ? 'Multipeer'
            : 'P2P';

    return Row(
      children: [
        Icon(
          state.transportType == P2PTransportType.wifiDirect
              ? Icons.wifi
              : Icons.devices,
          color: context.primaryColor,
          size: 32,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'High-Speed P2P',
                style: context.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                transportName,
                style: context.bodySmall.copyWith(
                      color: AppTheme.neutral400,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildModeSelector(P2PConnectionState state) {
    if (!state.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.mode == P2PConnectionMode.host
                ? null
                : () => _startAsHost(),
            icon: Icon(
              state.mode == P2PConnectionMode.host
                  ? Icons.check_circle
                  : Icons.router,
            ),
            label: Text(
              state.mode == P2PConnectionMode.host
                  ? 'Hosting'
                  : 'Start as Host',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.mode == P2PConnectionMode.host
                  ? context.successColor
                  : context.primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.mode == P2PConnectionMode.discovering
                ? () => _stopDiscovery()
                : () => _startDiscovery(),
            icon: Icon(
              state.mode == P2PConnectionMode.discovering
                  ? Icons.stop
                  : Icons.search,
            ),
            label: Text(
              state.mode == P2PConnectionMode.discovering
                  ? 'Stop Scan'
                  : 'Find Peers',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.mode == P2PConnectionMode.discovering
                  ? AppTheme.warning
                  : context.accentColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(P2PConnectionState state) {
    final stats = state.statistics;
    if (stats == null) return const SizedBox.shrink();

    return Card(
      color: AppTheme.neutral100,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.people,
              label: 'Connected',
              value: '${stats.connectedPeers}',
              color: context.successColor,
            ),
            _buildStatItem(
              icon: Icons.visibility,
              label: 'Discovered',
              value: '${stats.discoveredPeers}',
              color: AppTheme.info,
            ),
            _buildStatItem(
              icon: Icons.speed,
              label: 'Max Speed',
              value: stats.transportType == P2PTransportType.wifiDirect
                  ? '250 Mbps'
                  : 'Auto',
              color: context.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.neutral400,
          ),
        ),
      ],
    );
  }

  Widget _buildPeersList(List<P2PPeer> peers, P2PConnectionState state) {
    if (peers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.mode == P2PConnectionMode.host
                  ? Icons.router
                  : Icons.search_off,
              size: 64,
              color: AppTheme.neutral300,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              state.mode == P2PConnectionMode.host
                  ? 'Waiting for peers to connect...'
                  : state.mode == P2PConnectionMode.discovering
                      ? 'Searching for nearby peers...'
                      : 'No peers found',
              style: const TextStyle(color: AppTheme.neutral400),
              textAlign: TextAlign.center,
            ),
            if (state.mode == P2PConnectionMode.idle) ...[
              const SizedBox(height: AppTheme.spacingSm),
              const Text(
                'Start as host or find peers to begin',
                style: TextStyle(
                  color: AppTheme.neutral400,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: peers.length,
      itemBuilder: (context, index) {
        final peer = peers[index];
        return _buildPeerItem(peer, state);
      },
    );
  }

  Widget _buildPeerItem(P2PPeer peer, P2PConnectionState state) {
    final isConnected = peer.isConnected;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isConnected ? context.successColor : AppTheme.info,
          child: Icon(
            isConnected ? Icons.link : Icons.person,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: Text(
          peer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${peer.id.substring(0, 8)}...'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: isConnected ? context.successColor : AppTheme.neutral400,
                ),
                const SizedBox(width: 4),
                Text(
                  peer.status,
                  style: TextStyle(
                    color: isConnected ? context.successColor : AppTheme.neutral400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    peer.transportName,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isConnected
            ? IconButton(
                icon: Icon(Icons.link_off, color: context.errorColor),
                tooltip: 'Disconnect',
                onPressed: () => _disconnectFromPeer(peer.id),
              )
            : ElevatedButton(
                onPressed: () => _connectToPeer(peer.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Connect'),
              ),
      ),
    );
  }

  Future<void> _startAsHost() async {
    final notifier = ref.read(p2pConnectionNotifierProvider.notifier);
    await notifier.startAsHost();
    notifier.updateStatistics();
  }

  Future<void> _startDiscovery() async {
    final notifier = ref.read(p2pConnectionNotifierProvider.notifier);
    await notifier.startDiscovery();
    notifier.updateStatistics();
  }

  Future<void> _stopDiscovery() async {
    final notifier = ref.read(p2pConnectionNotifierProvider.notifier);
    await notifier.stopDiscovery();
    notifier.updateStatistics();
  }

  Future<void> _connectToPeer(String peerId) async {
    final notifier = ref.read(p2pConnectionNotifierProvider.notifier);
    final success = await notifier.connectToPeer(peerId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Connected to peer' : 'Failed to connect',
          ),
          backgroundColor: success ? context.successColor : context.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    notifier.updateStatistics();
  }

  Future<void> _disconnectFromPeer(String peerId) async {
    final notifier = ref.read(p2pConnectionNotifierProvider.notifier);
    await notifier.disconnect(peerId: peerId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Disconnected from peer'),
          backgroundColor: AppTheme.info,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    notifier.updateStatistics();
  }
}
