import '../models/visitor.dart';

List<Visitor> buildSampleVisitors() {
  final now = DateTime.now();
  return [
    Visitor(
      id: '',
      name: 'Arun Kumar',
      mobile: '9840012345',
      email: 'arun@example.com',
      type: 'Customer',
      project: 'Project A',
      purpose: 'Meeting',
      status: VisitorStatus.checkedIn,
      registeredAt: now.subtract(const Duration(hours: 2)),
      checkInTime: now.subtract(const Duration(hours: 1)),
    ),
    Visitor(
      id: '',
      name: 'Priya Sharma',
      mobile: '9884098840',
      type: 'Other',
      project: 'Project B',
      purpose: 'Interview',
      status: VisitorStatus.checkedOut,
      registeredAt: now.subtract(const Duration(hours: 5)),
      checkInTime: now.subtract(const Duration(hours: 4)),
      checkOutTime: now.subtract(const Duration(hours: 2)),
    ),
    Visitor(
      id: '',
      name: 'Rahul',
      mobile: '9791122334',
      type: 'Vendor',
      project: 'Project C',
      purpose: 'Delivery',
      registeredAt: now.subtract(const Duration(minutes: 40)),
    ),
    Visitor(
      id: '',
      name: 'Meena Lakshmi',
      mobile: '9444455667',
      type: 'Customer',
      project: 'Project B',
      purpose: 'Project review',
      registeredAt: now.subtract(const Duration(days: 1)),
    ),
  ];
}