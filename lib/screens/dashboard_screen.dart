import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/visitor_provider.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onViewAll;
  final VoidCallback onScan;

  const DashboardScreen({
    super.key,
    required this.onViewAll,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VisitorProvider>();
    final cs = Theme.of(context).colorScheme;

    if (p.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (p.error != null && p.visitors.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load visitors',
        subtitle: p.error!,
        action: ElevatedButton.icon(
          onPressed: p.load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    }

    final recent = p.visitors.take(3).toList();

    return RefreshIndicator(
      onRefresh: p.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ErrorBanner(message: p.error!, onRetry: p.refresh),
              ),

            // ---- hero card ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [ Color.fromARGB(255, 85, 64, 9), 
    Color.fromARGB(255, 111, 93, 45),],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Inside now',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('${p.activeNow}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.bold)),
                        Text('of ${p.total} total visitors',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Icon(Icons.apartment_rounded,
                      color: Colors.white24, size: 72),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- stat cards ----
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Visitors',
                    count: '${p.total}',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Checked In (total)',
                    count: '${p.checkedInTotal}',
                    icon: Icons.login,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Checked Out',
                    count: '${p.checkedOut}',
                    icon: Icons.logout,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Not Arrived Yet',
                    count: '${p.registeredCount}',
                    icon: Icons.hourglass_empty,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            const Text('Quick Actions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Shortcut(
                    icon: Icons.person_add_alt_1,
                    label: 'Register\nVisitor',
                    filled: true,
                    onTap: () => openForm(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Shortcut(
                    icon: Icons.list_alt,
                    label: 'Visitor\nList',
                    onTap: onViewAll,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Shortcut(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan\nQR Code',
                    onTap: onScan,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),
            Row(
              children: [
                const Expanded(
                  child: Text('Recent Visitors',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ),
                TextButton(onPressed: onViewAll, child: const Text('View all')),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              EmptyState(
                icon: Icons.people_outline,
                title: 'No visitor records',
                subtitle:
                    'Register a visitor, or import the sample visitors from Settings.',
              )
            else
              ...recent.map(
                (v) => VisitorCard(
                  visitor: v,
                  onTap: () => openDetail(context, v.id),
                ),
              ),
            SizedBox(height: 4, child: ColoredBox(color: cs.surface.withValues(alpha: 0))),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const padding = EdgeInsets.symmetric(vertical: 14, horizontal: 4);
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(height: 6),
        Text(label,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
      ],
    );

    return filled
        ? FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(padding: padding, shape: shape),
            child: child,
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(padding: padding, shape: shape),
            child: child,
          );
  }
}