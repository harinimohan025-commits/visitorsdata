import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';

class VisitorDetailPage extends StatelessWidget {
  final String visitorId;
  const VisitorDetailPage({super.key, required this.visitorId});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VisitorProvider>();
    final cs = Theme.of(context).colorScheme;
    final v = p.byId(visitorId);

    if (v == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visitor Details')),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Visitor not available',
          subtitle: 'This record was deleted or could not be loaded.',
        ),
      );
    }

    final busy = p.isBusy(v.id);
    final canCheckIn = v.status == VisitorStatus.registered && !busy;
    final canCheckOut = v.status == VisitorStatus.checkedIn && !busy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: busy ? null : () => openForm(context, visitor: v),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline, color: cs.error),
            onPressed: busy
                ? null
                : () async {
                    final nav = Navigator.of(context);
                    final deleted = await confirmAndDelete(context, p, v);
                    if (deleted) nav.pop();
                  },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(v.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StatusChip(status: v.status),
                  const SizedBox(height: 16),
                  // QR always sits on white so it scans in dark theme too
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: qrPayload(v.id),
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('ID: ${v.id}',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, letterSpacing: 1)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _info(context, Icons.phone_outlined, 'Phone', v.mobile),
                if (v.email.isNotEmpty)
                  _info(context, Icons.email_outlined, 'Email', v.email),
                _info(context, Icons.badge_outlined, 'Visitor Type', v.type),
                _info(context, Icons.folder_outlined, 'Project', v.project),
                if (v.purpose.isNotEmpty)
                  _info(context, Icons.notes_outlined, 'Purpose', v.purpose),
                _info(context, Icons.event_outlined, 'Registered',
                    fmtTime(v.registeredAt)),
                _info(context, Icons.login, 'Check-in', fmtTime(v.checkInTime)),
                _info(context, Icons.logout, 'Check-out',
                    fmtTime(v.checkOutTime)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (v.status == VisitorStatus.checkedOut)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Visit completed',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canCheckIn
                      ? () => runCheck(context, p, v, checkIn: true)
                      : null,
                  icon: busy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Check-in'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canCheckOut
                      ? () => runCheck(context, p, v, checkIn: false)
                      : null,
                  icon: const Icon(Icons.logout),
                  label: const Text('Check-out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(BuildContext context, IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
}