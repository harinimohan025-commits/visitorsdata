import 'package:flutter/material.dart';

enum VisitorStatus { registered, checkedIn, checkedOut }

extension VisitorStatusX on VisitorStatus {
  String get label => switch (this) {
        VisitorStatus.registered => 'Registered',
        VisitorStatus.checkedIn => 'Checked In',
        VisitorStatus.checkedOut => 'Checked Out',
      };

  String get apiValue => switch (this) {
        VisitorStatus.registered => 'registered',
        VisitorStatus.checkedIn => 'checkedIn',
        VisitorStatus.checkedOut => 'checkedOut',
      };

  Color get color => switch (this) {
        VisitorStatus.registered => Colors.purple,
        VisitorStatus.checkedIn => Colors.green,
        VisitorStatus.checkedOut => Colors.orange,
      };

  static VisitorStatus fromApi(dynamic value) {
    final s = (value ?? '')
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_\-]'), '');
    return switch (s) {
      'checkedin' => VisitorStatus.checkedIn,
      'checkedout' => VisitorStatus.checkedOut,
      _ => VisitorStatus.registered,
    };
  }
}

const List<String> kVisitorTypes = ['Customer', 'Vendor','Interview', 'Other'];
const List<String> kProjects = ['Project A', 'Project B', 'Project C','other'];

DateTime? _parseDate(dynamic x) {
  if (x == null) return null;
  final s = x.toString().trim();
  if (s.isEmpty) return null;
  final n = x is num ? x.toInt() : int.tryParse(s);
  if (n != null) {
    // unix seconds or milliseconds
    return DateTime.fromMillisecondsSinceEpoch(n < 100000000000 ? n * 1000 : n);
  }
  return DateTime.tryParse(s)?.toLocal();
}

class Visitor {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String type;
  final String project;
  final String purpose;
  final VisitorStatus status;
  final DateTime registeredAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  const Visitor({
    required this.id,
    required this.name,
    required this.mobile,
    this.email = '',
    required this.type,
    required this.project,
    this.purpose = '',
    this.status = VisitorStatus.registered,
    required this.registeredAt,
    this.checkInTime,
    this.checkOutTime,
  });

  Visitor copyWith({
    String? name,
    String? email,
    String? mobile,
    String? type,
    String? project,
    String? purpose,
    VisitorStatus? status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
  }) {
    return Visitor(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      type: type ?? this.type,
      project: project ?? this.project,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      registeredAt: registeredAt,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }

  factory Visitor.fromJson(Map<String, dynamic> j) {
    return Visitor(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      mobile: (j['mobile'] ?? '').toString(),
      type: (j['visitorType'] ?? 'Other').toString(),
      project: (j['project'] ?? '').toString(),
      purpose: (j['purpose'] ?? '').toString(),
      status: VisitorStatusX.fromApi(j['status']),
      registeredAt:
          _parseDate(j['registeredAt']) ?? _parseDate(j['createdAt']) ?? DateTime.now(),
      checkInTime: _parseDate(j['checkInTime']),
      checkOutTime: _parseDate(j['checkOutTime']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'mobile': mobile,
        'visitorType': type,
        'project': project,
        'purpose': purpose,
        'status': status.apiValue,
        'registeredAt': registeredAt.toUtc().toIso8601String(),
        'checkInTime': checkInTime?.toUtc().toIso8601String() ?? '',
        'checkOutTime': checkOutTime?.toUtc().toIso8601String() ?? '',
      };
}