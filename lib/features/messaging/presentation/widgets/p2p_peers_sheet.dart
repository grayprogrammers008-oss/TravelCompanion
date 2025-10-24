import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/p2p_connection_manager.dart';
import '../providers/p2p_providers.dart';

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
    final notifier = ref.read(p2pConnectionNotifierProvider.notifier);
    await notifier.initialize(
      userId: widget.userId,
      userName: widget.userName,
    );
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

          // Connection Mode Selector
          _buildModeSelector(state),
          const SizedBox(height: AppTheme.spacingMd),

          // Statistics
          _buildStatistics(state),
          const SizedBox(height: AppTheme.spacingMd),

          // Peers List
          Expanded(
            child: peersAsync.when(
              data: (peers) => _buildPeersList(peers, state),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading peers: $error',
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
            ),
          ),
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
          color: AppTheme.primaryTeal,
          size: 32,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'High-Speed P2P',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                transportName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  ? AppTheme.success
                  : AppTheme.primaryTeal,
              foregroundColor: Colors.white,
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
                  : AppTheme.accentCoral,
              foregroundColor: Colors.white,
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
              color: AppTheme.success,
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
              color: AppTheme.primaryTeal,
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
          backgroundColor: isConnected ? AppTheme.success : AppTheme.info,
          child: Icon(
            isConnected ? Icons.link : Icons.person,
            color: Colors.white,
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
                  color: isConnected ? AppTheme.success : AppTheme.neutral400,
                ),
                const SizedBox(width: 4),
                Text(
                  peer.status,
                  style: TextStyle(
                    color: isConnected ? AppTheme.success : AppTheme.neutral400,
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
                    color: AppTheme.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    peer.transportName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isConnected
            ? IconButton(
                icon: const Icon(Icons.link_off, color: AppTheme.error),
                tooltip: 'Disconnect',
                onPressed: () => _disconnectFromPeer(peer.id),
              )
            : ElevatedButton(
                onPressed: () => _connectToPeer(peer.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
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
          backgroundColor: success ? AppTheme.success : AppTheme.error,
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
        const SnackBar(
          content: Text('Disconnected from peer'),
          backgroundColor: AppTheme.info,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    notifier.updateStatistics();
  }
}
