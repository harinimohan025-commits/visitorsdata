import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/theme_provider.dart';
import '../providers/visitor_provider.dart';
import '../utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _testing = false;
  bool _importing = false;

  Future<void> _test() async {
    final messenger = ScaffoldMessenger.of(context);
    final p = context.read<VisitorProvider>();
    setState(() => _testing = true);
    await p.refresh(); // real GET
    if (mounted) setState(() => _testing = false);
    if (p.error == null) {
      showMsgOn(messenger,
          'Connected. ${p.visitors.length} record(s) fetched from MockAPI');
    } else {
      showMsgOn(messenger, p.error!, error: true);
    }
  }

  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);
    final p = context.read<VisitorProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import sample visitors?'),
        content: const Text(
            'This adds the 4 original sample visitors to MockAPI. Visitors whose phone number already exists are skipped, so running it again will not create duplicates.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _importing = true);
    final r = await p.importSamples();
    if (mounted) setState(() => _importing = false);

    if (r.error != null) {
      showMsgOn(
          messenger,
          'Import stopped: ${r.error} (created ${r.created}, skipped ${r.skipped})',
          error: true);
    } else {
      showMsgOn(messenger,
          'Import finished: ${r.created} created, ${r.skipped} already existed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VisitorProvider>();
    final theme = context.watch<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appearance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {theme.mode},
                    onSelectionChanged: (s) =>
                        context.read<ThemeProvider>().setMode(s.first),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.cloud_outlined, color: cs.primary),
                title: const Text('API endpoint'),
                subtitle: Text('${ApiConfig.baseUrl}/${ApiConfig.resource}'),
              ),
              ListTile(
                leading: Icon(
                  ApiConfig.isConfigured
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  color: ApiConfig.isConfigured ? Colors.green : cs.error,
                ),
                title: Text(ApiConfig.isConfigured
                    ? 'URL configured'
                    : 'URL not configured'),
                subtitle: Text(ApiConfig.isConfigured
                    ? 'Records currently loaded: ${p.total}'
                    : 'Edit baseUrl in lib/config/api_config.dart'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _testing ? null : _test,
          icon: _testing
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.wifi_tethering),
          label: const Text('Test connection'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _importing ? null : _import,
          icon: _importing
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_outlined),
          label: const Text('Import sample visitors (one-time)'),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(' Visitor Management',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }
}