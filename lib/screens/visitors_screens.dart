import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  VisitorStatus? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Visitor> _filtered(List<Visitor> all) {
    final q = _query.trim().toLowerCase();
    return all.where((v) {
      if (_filter != null && v.status != _filter) return false;
      if (q.isEmpty) return true;
      return v.name.toLowerCase().contains(q) ||
          v.email.toLowerCase().contains(q) ||
          v.mobile.contains(q) ||
          v.id.toLowerCase() == q ||
          v.project.toLowerCase().contains(q) ||
          v.type.toLowerCase().contains(q) ||
          v.purpose.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VisitorProvider>();

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

    final list = _filtered(p.visitors);
    final filtering = _query.isNotEmpty || _filter != null;

    return Column(
      children: [
        if (p.error != null) ErrorBanner(message: p.error!, onRetry: p.refresh),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SearchBar(
            controller: _search,
            hintText: 'Search name, email, mobile, project...',
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: const WidgetStatePropertyAll(Colors.white),
            leading: const Icon(Icons.search),
            padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16)),
            onChanged: (v) => setState(() => _query = v),
            trailing: [
              if (_query.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final s in VisitorStatus.values) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(s.label),
                  selected: _filter == s,
                  onSelected: (_) => setState(() => _filter = s),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? EmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No visitor records',
                  subtitle: filtering
                      ? 'Try changing your search or filter.'
                      : 'Register a visitor, or import the sample visitors from Settings.',
                  action: filtering
                      ? null
                      : ElevatedButton.icon(
                          onPressed: () => openForm(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Register visitor'),
                        ),
                )
              : RefreshIndicator(
                  onRefresh: p.refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final v = list[i];
                      return VisitorCard(
                        visitor: v,
                        showActions: true,
                        busy: p.isBusy(v.id),
                        onTap: () => openDetail(context, v.id),
                        onQr: () => showQrDialog(context, v),
                        onCheck: () => toggleCheck(context, p, v),
                        onEdit: () => openForm(context, visitor: v),
                        onDelete: () => confirmAndDelete(context, p, v),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}