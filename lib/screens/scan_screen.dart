import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import '../services/visitor_api.dart';
import '../utils/helpers.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _handling = false;
  bool _loading = false;
  String? _lastCode;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _safeStart();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _safeStop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _safeStart() async {
    try {
      await _controller.start();
    } catch (_) {}
  }

  Future<void> _safeStop() async {
    try {
      await _controller.stop();
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) {
        _handleCode(v);
        return;
      }
    }
  }

  Future<void> _handleCode(String raw, {bool manual = false}) async {
    if (_handling) return;
    final code = raw.trim();

    // ignore the same QR for 3 seconds so the sheet does not reopen in a loop
    if (!manual &&
        code == _lastCode &&
        DateTime.now().difference(_lastAt) < const Duration(seconds: 3)) {
      return;
    }

    _handling = true;
    _lastCode = code;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<VisitorProvider>();

    try {
      // 1. validate QR format
      final id = parseVisitorId(code);
      if (id == null) {
        showMsgOn(messenger, 'Invalid QR code', error: true);
        await Future.delayed(const Duration(seconds: 2));
        return;
      }

      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _loading = true);

      // 2. ask the server for this visitor
      Visitor? visitor;
      String? failure;
      try {
        visitor = await provider.fetchById(id);
      } on ApiException catch (e) {
        failure = e.statusCode == 404 ? 'Visitor does not exist' : e.message;
      } catch (_) {
        failure = 'Something went wrong. Please try again.';
      } finally {
        if (mounted) setState(() => _loading = false);
      }

      if (visitor == null) {
        showMsgOn(messenger, failure ?? 'Visitor not found', error: true);
        await Future.delayed(const Duration(seconds: 2));
        return;
      }
      if (!mounted) return;

      // 3. show visitor + check-in / check-out
      final found = visitor;
      await _safeStop();
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => ScanResultSheet(visitorId: found.id),
      );
      if (mounted) await _safeStart();
    } finally {
      _lastAt = DateTime.now();
      _handling = false;
    }
  }

  Future<void> _manualEntry() async {
    final c = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter visitor ID'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 5'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Find')),
        ],
      ),
    );
    c.dispose();
    if (id != null && id.trim().isNotEmpty) _handleCode(id, manual: true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            final details = error.errorDetails?.message;
            return Container(
              color: Colors.black87,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography_outlined,
                      color: Colors.white, size: 56),
                  const SizedBox(height: 12),
                  const Text('Camera could not start',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(error.errorCode.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70)),
                  if (details != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(details,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _safeStart, child: const Text('Retry')),
                  TextButton(
                      onPressed: _manualEntry,
                      child: const Text('Enter ID manually')),
                ],
              ),
            );
          },
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Enter ID manually',
                icon: const Icon(Icons.keyboard_outlined),
                onPressed: _manualEntry,
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Torch',
                icon: const Icon(Icons.flash_on),
                onPressed: () => _controller.toggleTorch(),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Switch camera',
                icon: const Icon(Icons.cameraswitch_outlined),
                onPressed: () => _controller.switchCamera(),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text('Point the camera at the visitor QR',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        if (_loading)
          Container(
            color: Colors.black45,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }
}


class ScanResultSheet extends StatefulWidget {
  final String visitorId;
  const ScanResultSheet({super.key, required this.visitorId});

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  String? _error;

  Future<void> _act(VisitorProvider p, Visitor v, {required bool checkIn}) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _error = null);
    try {
      final saved = checkIn ? await p.checkIn(v) : await p.checkOut(v);
      if (saved == null) return;
      nav.pop();
      showMsgOn(messenger,
          checkIn ? '${saved.name} checked in' : '${saved.name} checked out');
    } catch (e) {
      if (mounted) setState(() => _error = errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VisitorProvider>();
    final v = p.byId(widget.visitorId);
    if (v == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Visitor no longer available'),
        ),
      );
    }

    final busy = p.isBusy(v.id);
    final color = v.status.color;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.person, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(v.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('ID ${v.id}  •  ${v.mobile}',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text('${v.project}  •  ${v.type}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Chip(
              label: Text(v.status.label),
              labelStyle: TextStyle(color: color, fontSize: 12),
              backgroundColor: color.withValues(alpha: 0.12),
              side: BorderSide.none,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade600)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (v.status == VisitorStatus.registered && !busy)
                        ? () => _act(p, v, checkIn: true)
                        : null,
                    icon: busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.login),
                    label: const Text('Check-in'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (v.status == VisitorStatus.checkedIn && !busy)
                        ? () => _act(p, v, checkIn: false)
                        : null,
                    icon: const Icon(Icons.logout),
                    label: const Text('Check-out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop();
                openDetail(nav.context, v.id);
              },
              child: const Text('View full details'),
            ),
          ],
        ),
      ),
    );
  }
}