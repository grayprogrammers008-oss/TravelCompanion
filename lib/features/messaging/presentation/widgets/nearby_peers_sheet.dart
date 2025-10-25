import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../data/services/ble_service.dart';
import '../../data/services/mesh_coordinator.dart';

/// Nearby Peers Bottom Sheet
/// Shows discovered BLE peers and connection status
class NearbyPeersSheet extends StatefulWidget {
  final String userId;
  final String userName;

  const NearbyPeersSheet({
    super.key,
    required this.userId,
    required this.userName,
  });

  /// Show nearby peers sheet
  static void show(
    BuildContext context, {
    required String userId,
    required String userName,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (buildContext) => NearbyPeersSheet(
        userId: userId,
        userName: userName,
      ),
    );
  }

  @override
  State<NearbyPeersSheet> createState() => _NearbyPeersSheetState();
}

class _NearbyPeersSheetState extends State<NearbyPeersSheet> {
  final BLEService _bleService = BLEService();
  final MeshCoordinator _meshCoordinator = MeshCoordinator();

  bool _isScanning = false;
  List<BLEPeer> _peers = [];
  MeshStatistics? _meshStats;

  @override
  void initState() {
    super.initState();
    _initializeAndScan();
    _setupListeners();
  }

  Future<void> _initializeAndScan() async {
    try {
      // Initialize services
      final bleInitialized = await _bleService.initialize();
      if (!bleInitialized) {
        _showError('Bluetooth initialization failed');
        return;
      }

      await _meshCoordinator.initialize(
        userId: widget.userId,
        userName: widget.userName,
      );

      // Start scanning
      await _startScanning();
    } catch (e) {
      _showError('Initialization failed: $e');
    }
  }

  void _setupListeners() {
    // Listen to peer discoveries
    _bleService.peersStream.listen((peers) {
      if (mounted) {
        setState(() {
          _peers = peers;
        });
      }
    });

    // Update mesh stats periodically
    Future.delayed(const Duration(seconds: 2), _updateMeshStats);
  }

  Future<void> _startScanning() async {
    setState(() => _isScanning = true);

    await _bleService.startScanning(
      userId: widget.userId,
      userName: widget.userName,
      timeout: const Duration(seconds: 30),
    );

    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  void _updateMeshStats() {
    if (mounted) {
      setState(() {
        _meshStats = _meshCoordinator.getStatistics();
      });

      // Update again after 5 seconds
      Future.delayed(const Duration(seconds: 5), _updateMeshStats);
    }
  }

  Future<void> _connectToPeer(BLEPeer peer) async {
    try {
      final success = await _bleService.connectToPeer(peer.id);
      if (success) {
        _showSuccess('Connected to ${peer.name}');
      } else {
        _showError('Failed to connect to ${peer.name}');
      }
    } catch (e) {
      _showError('Connection error: $e');
    }
  }

  Future<void> _disconnectFromPeer(BLEPeer peer) async {
    try {
      await _bleService.disconnectFromPeer(peer.id);
      _showSuccess('Disconnected from ${peer.name}');
    } catch (e) {
      _showError('Disconnect error: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingMd),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bluetooth_searching,
                      color: context.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nearby Peers (BLE Scan)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neutral900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Scan for nearby devices',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isScanning ? Icons.stop : Icons.refresh,
                        color: context.primaryColor,
                      ),
                      onPressed: _isScanning
                          ? () => _bleService.stopScanning()
                          : _startScanning,
                      tooltip: _isScanning ? 'Stop scanning' : 'Scan again',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: AppTheme.neutral600,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                // Limitation notice
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      const Expanded(
                        child: Text(
                          'BLE can only scan. Use WiFi Direct icon (top-right) for two-way P2P connectivity.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.neutral700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mesh statistics
          if (_meshStats != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.devices,
                    label: 'Nodes',
                    value: '${_meshStats!.connectedNodes}',
                  ),
                  _buildStatItem(
                    icon: Icons.message,
                    label: 'Cached',
                    value: '${_meshStats!.cachedMessages}',
                  ),
                  _buildStatItem(
                    icon: Icons.route,
                    label: 'Routes',
                    value: '${_meshStats!.knownRoutes}',
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppTheme.spacingMd),

          // Scanning indicator
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  Text(
                    'Scanning for nearby peers...',
                    style: TextStyle(
                      color: AppTheme.neutral600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Peers list
          Expanded(
            child: _peers.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    itemCount: _peers.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final peer = _peers[index];
                      return _buildPeerItem(peer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.neutral900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildPeerItem(BLEPeer peer) {
    final isConnected = _bleService.isConnectedTo(peer.id);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isConnected ? Theme.of(context).colorScheme.primary : AppTheme.neutral200,
        child: Icon(
          isConnected ? Icons.link : Icons.person,
          color: isConnected ? Theme.of(context).colorScheme.onPrimary : AppTheme.neutral600,
        ),
      ),
      title: Text(
        peer.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral900,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signal: ${peer.signalStrength} (${peer.rssi} dBm)',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Distance: ~${peer.estimatedDistance.toStringAsFixed(1)}m',
            style: const TextStyle(fontSize: 11, color: AppTheme.neutral600),
          ),
        ],
      ),
      trailing: isConnected
          ? IconButton(
              icon: const Icon(Icons.link_off, color: AppTheme.error),
              onPressed: () => _disconnectFromPeer(peer),
              tooltip: 'Disconnect',
            )
          : ElevatedButton(
              onPressed: () => _connectToPeer(peer),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
              ),
              child: const Text('Connect'),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
              size: 64,
              color: AppTheme.neutral300,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              _isScanning ? 'Searching...' : 'No nearby peers found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _isScanning
                  ? 'Looking for BLE devices broadcasting Travel Companion service'
                  : 'No devices found with Travel Companion BLE service',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.info.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: AppTheme.info,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      const Expanded(
                        child: Text(
                          'For full P2P connectivity:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neutral800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  const Text(
                    '• BLE Scan-Only: Can only discover devices broadcasting Travel Companion service\n\n• WiFi Direct: Tap the WiFi icon (📶) in chat screen for full two-way P2P with host/discover modes',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bleService.stopScanning();
    super.dispose();
  }
}
