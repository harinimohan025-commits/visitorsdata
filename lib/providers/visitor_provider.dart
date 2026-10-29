import 'package:flutter/foundation.dart';

import '../data/sample_visitors.dart';
import '../models/visitor.dart';
import '../services/visitor_api.dart';

class ImportResult {
  final int created;
  final int skipped;
  final String? error;
  const ImportResult(this.created, this.skipped, {this.error});
}

class VisitorProvider extends ChangeNotifier {
  VisitorProvider(this._api);

  final VisitorApi _api;
  final List<Visitor> _visitors = [];
  final Set<String> _busy = {};
  bool _loading = false;
  bool _importing = false;
  String? _error;

  List<Visitor> get visitors => List.unmodifiable(_visitors);
  bool get isLoading => _loading;
  String? get error => _error;
  bool isBusy(String id) => _busy.contains(id);

  // ---- dashboard numbers (all calculated from API records) ----
  int get total => _visitors.length;
  int get registeredCount =>
      _visitors.where((v) => v.status == VisitorStatus.registered).length;
  int get activeNow =>
      _visitors.where((v) => v.status == VisitorStatus.checkedIn).length;
  int get checkedOut =>
      _visitors.where((v) => v.status == VisitorStatus.checkedOut).length;
  // everyone who has checked in at some point (active + already left)
  int get checkedInTotal =>
      _visitors.where((v) => v.status != VisitorStatus.registered).length;

  Visitor? byId(String id) {
    for (final v in _visitors) {
      if (v.id == id) return v;
    }
    return null;
  }

  static String _msg(Object e) =>
      e is ApiException ? e.message : 'Something went wrong. Please try again.';

  void _setAll(List<Visitor> list) {
    _visitors
      ..clear()
      ..addAll(list)
      ..sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
  }

  void _replace(Visitor v) {
    final i = _visitors.indexWhere((e) => e.id == v.id);
    if (i == -1) {
      _visitors.insert(0, v);
    } else {
      _visitors[i] = v;
    }
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _setAll(await _api.getAll());
    } catch (e) {
      _error = _msg(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      _setAll(await _api.getAll());
      _error = null;
    } catch (e) {
      _error = _msg(e);
    }
    notifyListeners();
  }

  Future<Visitor> fetchById(String id) async {
    final v = await _api.getById(id);
    _replace(v);
    notifyListeners();
    return v;
  }


  Future<Visitor> register(Visitor draft) async {
    final created = await _api.create(draft);
    Visitor verified;
    try {
      verified = await _api.getById(created.id);
    } catch (_) {
      throw const ApiException(
          'Visitor was sent but could not be confirmed on the server. Pull down to refresh and check the list.');
    }
    if (verified.name != draft.name || verified.mobile != draft.mobile) {
      throw const ApiException(
          'Server saved the record but fields did not match. Check the MockAPI resource fields.');
    }
    _replace(verified);
    notifyListeners();
    return verified;
  }


  Future<Visitor> update(Visitor v) async {
    final saved = await _api.update(v);
    _replace(saved);
    notifyListeners();
    return saved;
  }


  Future<bool> remove(String id) async {
    if (!_busy.add(id)) return false;
    notifyListeners();
    try {
      await _api.delete(id);
      _visitors.removeWhere((v) => v.id == id);
      return true;
    } finally {
      _busy.remove(id);
      notifyListeners();
    }
  }


  Future<Visitor?> checkIn(Visitor v) => _transition(v, VisitorStatus.checkedIn);
  Future<Visitor?> checkOut(Visitor v) =>
      _transition(v, VisitorStatus.checkedOut);

  Future<Visitor?> _transition(Visitor stale, VisitorStatus to) async {
    if (!_busy.add(stale.id)) return null;
    notifyListeners();
    try {
      final v = byId(stale.id) ?? stale;
      if (to == VisitorStatus.checkedIn) {
        if (v.status == VisitorStatus.checkedIn) {
          throw ApiException('${v.name} is already checked in');
        }
        if (v.status == VisitorStatus.checkedOut) {
          throw ApiException('${v.name} has already completed the visit');
        }
      } else {
        if (v.status == VisitorStatus.registered) {
          throw ApiException('${v.name} has not checked in yet');
        }
        if (v.status == VisitorStatus.checkedOut) {
          throw ApiException('${v.name} is already checked out');
        }
      }

      final now = DateTime.now();
      final changed = to == VisitorStatus.checkedIn
          ? v.copyWith(status: to, checkInTime: now)
          : v.copyWith(status: to, checkOutTime: now);

      final saved = await _api.update(changed);
      if (saved.status != to) {
        throw const ApiException(
            'Server did not save the new status. Check the "status" field in MockAPI.');
      }
      _replace(saved);
      return saved;
    } finally {
      _busy.remove(stale.id);
      notifyListeners();
    }
  }


  Future<ImportResult> importSamples() async {
    if (_importing) return const ImportResult(0, 0, error: 'Import already running');
    _importing = true;
    int created = 0, skipped = 0;
    try {
      final existing = await _api.getAll();
      final mobiles = existing.map((v) => v.mobile.trim()).toSet();
      for (final s in buildSampleVisitors()) {
        if (mobiles.contains(s.mobile)) {
          skipped++;
          continue;
        }
        final saved = await _api.create(s);
        mobiles.add(saved.mobile);
        created++;
      }
      await refresh();
      return ImportResult(created, skipped);
    } catch (e) {
      await refresh();
      return ImportResult(created, skipped, error: _msg(e));
    } finally {
      _importing = false;
    }
  }
}