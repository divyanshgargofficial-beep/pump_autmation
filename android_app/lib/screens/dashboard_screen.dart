import 'dart:async';

import 'package:flutter/material.dart';

import '../models/api_result.dart';
import '../models/esp_status.dart';
import '../services/esp_api_service.dart';
import '../services/esp_discovery_service.dart';
import '../services/settings_service.dart';
import '../utils/time_format.dart';
import '../widgets/action_button.dart';
import '../widgets/status_tile.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.settingsService,
    super.key,
  });

  final SettingsService settingsService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _pollInterval = Duration(seconds: 1);

  final _discovery = const EspDiscoveryService();
  Timer? _timer;
  EspApiService? _api;
  EspStatus? _status;
  DateTime? _lastRefresh;
  String? _error;
  bool _loading = true;
  bool _commandRunning = false;

  bool get _connected => _error == null && _status != null;

  @override
  void initState() {
    super.initState();
    widget.settingsService.addListener(_rebuildApi);
    _rebuildApi();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.settingsService.removeListener(_rebuildApi);
    _api?.dispose();
    super.dispose();
  }

  void _rebuildApi() {
    _api?.dispose();
    try {
      _api = EspApiService(
        baseUri: _discovery.resolveBaseUri(widget.settingsService.settings),
      );
      _refresh();
    } on FormatException catch (error) {
      setState(() {
        _status = null;
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    final api = _api;
    if (api == null || _commandRunning) {
      return;
    }

    if (!silent) {
      setState(() => _loading = true);
    }

    final result = await api.fetchStatus();
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _status = result.data;
        _lastRefresh = DateTime.now();
        _error = null;
      } else {
        _status = null;
        _error = result.error;
      }
    });
  }

  Future<void> _runCommand(
    Future<ApiResult<void>> Function(EspApiService api) action,
  ) async {
    final api = _api;
    if (api == null || !_connected) {
      return;
    }

    setState(() {
      _commandRunning = true;
      _error = null;
    });

    final result = await action(api);
    if (!mounted) {
      return;
    }

    setState(() {
      _commandRunning = false;
      if (!result.isSuccess) {
        _error = result.error;
      }
    });
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final green = Colors.green.shade700;
    final red = Colors.red.shade700;
    final neutral = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tank Controller'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(
                    settingsService: widget.settingsService,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_loading) const SizedBox(height: 16),
            if (_error != null) _ErrorBanner(message: _error!),
            if (_error != null) const SizedBox(height: 16),
            _Header(
              connected: _connected,
              lastRefresh: _lastRefresh,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 640;
                return GridView.count(
                  crossAxisCount: wide ? 2 : 1,
                  childAspectRatio: wide ? 3.2 : 4.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatusTile(
                      title: 'ESP Connection',
                      value: _connected ? 'Connected' : 'ESP Offline',
                      icon: Icons.router_outlined,
                      color: _connected ? green : red,
                    ),
                    StatusTile(
                      title: 'WiFi Status',
                      value: status?.wifiConnected == true ? 'Connected' : 'Offline',
                      icon: Icons.wifi,
                      color: status?.wifiConnected == true ? green : red,
                    ),
                    StatusTile(
                      title: 'Pump Status',
                      value: status?.pump == true ? 'Running' : 'Stopped',
                      icon: Icons.power_settings_new,
                      color: status?.pump == true ? green : neutral,
                    ),
                    StatusTile(
                      title: 'Tank Status',
                      value: status?.tankFull == true ? 'Tank Full' : 'Filling',
                      icon: Icons.water_drop_outlined,
                      color: status?.tankFull == true ? red : green,
                    ),
                    StatusTile(
                      title: 'Lockout Status',
                      value: status?.lockout == true ? 'Lockout Active' : 'Ready',
                      icon: Icons.lock_outline,
                      color: status?.lockout == true ? red : green,
                    ),
                    StatusTile(
                      title: 'Runtime Counter',
                      value: formatRuntime(status?.runtime ?? 0),
                      icon: Icons.timer_outlined,
                      color: status?.pump == true ? green : neutral,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _Controls(
              enabled: _connected && !_commandRunning,
              status: status,
              onStart: () => _runCommand((api) => api.startPump()),
              onStop: () => _runCommand((api) => api.stopPump()),
              onClear: () => _runCommand((api) => api.clearLock()),
              onRefresh: () => _refresh(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.connected,
    required this.lastRefresh,
  });

  final bool connected;
  final DateTime? lastRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = lastRefresh == null
        ? 'Never'
        : TimeOfDay.fromDateTime(lastRefresh!).format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          connected ? 'Connected' : 'ESP Offline',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Last refresh: $time',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.enabled,
    required this.status,
    required this.onStart,
    required this.onStop,
    required this.onClear,
    required this.onRefresh,
  });

  final bool enabled;
  final EspStatus? status;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onClear;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final canStart = enabled && status?.lockout != true && status?.tankFull != true;

    return Column(
      children: [
        ActionButton(
          label: 'START PUMP',
          icon: Icons.play_arrow,
          onPressed: canStart ? onStart : null,
        ),
        const SizedBox(height: 10),
        ActionButton(
          label: 'STOP PUMP',
          icon: Icons.stop,
          destructive: true,
          onPressed: enabled ? onStop : null,
        ),
        const SizedBox(height: 10),
        ActionButton(
          label: 'CLEAR LOCK',
          icon: Icons.lock_open,
          onPressed: enabled ? onClear : null,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: enabled ? onRefresh : null,
          icon: const Icon(Icons.refresh),
          label: const Text('REFRESH'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
