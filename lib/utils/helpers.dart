import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import '../screens/visitor_detail_page.dart';
import '../screens/visitors_form_page.dart';
import '../services/visitor_api.dart';

const String kQrPrefix = 'visteel:visitor:';
String qrPayload(String id) => '$kQrPrefix$id';

final RegExp _idRegex = RegExp(r'^[A-Za-z0-9_\-]{1,64}$');

String? parseVisitorId(String raw) {
  var s = raw.trim();
  if (s.startsWith(kQrPrefix)) s = s.substring(kQrPrefix.length);
  return _idRegex.hasMatch(s) ? s : null;
}

String fmtTime(DateTime? t) {
  if (t == null) return '-';
  final l = t.toLocal();
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final m = l.minute.toString().padLeft(2, '0');
  final ap = l.hour >= 12 ? 'PM' : 'AM';
  return '${l.day}/${l.month}/${l.year}  $h:$m $ap';
}

String errText(Object e) =>
    e is ApiException ? e.message : 'Something went wrong. Please try again.';

void showMsgOn(ScaffoldMessengerState messenger, String message,
    {bool error = false}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
}

void showMsg(BuildContext context, String message, {bool error = false}) =>
    showMsgOn(ScaffoldMessenger.of(context), message, error: error);

Future<void> openForm(BuildContext context, {Visitor? visitor}) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => VisitorFormPage(visitor: visitor)),
  );
}

Future<void> openDetail(BuildContext context, String id) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => VisitorDetailPage(visitorId: id)),
  );
}

Future<bool> confirmAndDelete(
    BuildContext context, VisitorProvider provider, Visitor v) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 32),
      title: const Text('Delete visitor?'),
      content: Text('${v.name} will be permanently removed.'),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true) return false;

  try {
    final deleted = await provider.remove(v.id);
    if (deleted) showMsgOn(messenger, '${v.name} deleted');
    return deleted;
  } catch (e) {
    showMsgOn(messenger, errText(e), error: true);
    return false;
  }
}

Future<void> runCheck(
  BuildContext context,
  VisitorProvider provider,
  Visitor v, {
  required bool checkIn,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final saved = checkIn ? await provider.checkIn(v) : await provider.checkOut(v);
    if (saved == null) return;
    showMsgOn(messenger,
        checkIn ? '${saved.name} checked in' : '${saved.name} checked out');
  } catch (e) {
    showMsgOn(messenger, errText(e), error: true);
  }
}

Future<void> toggleCheck(
    BuildContext context, VisitorProvider provider, Visitor v) async {
  switch (v.status) {
    case VisitorStatus.registered:
      await runCheck(context, provider, v, checkIn: true);
    case VisitorStatus.checkedIn:
      await runCheck(context, provider, v, checkIn: false);
    case VisitorStatus.checkedOut:
      showMsg(context, '${v.name} has already completed the visit', error: true);
  }
}

void showQrDialog(BuildContext context, Visitor v) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(v.name, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: qrPayload(v.id),
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          Text('ID: ${v.id}', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}