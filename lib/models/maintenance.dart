import 'dart:convert';

enum MaintenanceStatus { upcoming, completed, overdue }

class Maintenance {
  final int? id;
  final int customerId;
  final DateTime installationDate;
  final DateTime nextMaintenanceDate;
  final String maintenanceType; // "2-month" or "6-month"
  final MaintenanceStatus status;
  final String? notes;
  final DateTime? completedDate;
  final String? issue;      // Issue found during maintenance
  final String? fix;        // Fix applied during maintenance
  final double? cost;       // Cost of the maintenance/repair

  Maintenance({
    this.id,
    required this.customerId,
    required this.installationDate,
    required this.nextMaintenanceDate,
    required this.maintenanceType,
    required this.status,
    this.notes,
    this.completedDate,
    this.issue,
    this.fix,
    this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'installationDate': installationDate.millisecondsSinceEpoch,
      'nextMaintenanceDate': nextMaintenanceDate.millisecondsSinceEpoch,
      'maintenanceType': maintenanceType,
      'status': status.toString().split('.').last,
      'notes': notes,
      'completedDate': completedDate?.millisecondsSinceEpoch,
      'issue': issue,
      'fix': fix,
      'cost': cost,
    };
  }

  factory Maintenance.fromMap(Map<String, dynamic> map) {
    return Maintenance(
      id: map['id'],
      customerId: map['customerId'],
      installationDate: DateTime.fromMillisecondsSinceEpoch(map['installationDate']),
      nextMaintenanceDate: DateTime.fromMillisecondsSinceEpoch(map['nextMaintenanceDate']),
      maintenanceType: map['maintenanceType'],
      status: MaintenanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => MaintenanceStatus.upcoming,
      ),
      notes: map['notes'],
      completedDate: map['completedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedDate'])
          : null,
      issue: map['issue'],
      fix: map['fix'],
      cost: map['cost'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Maintenance.fromJson(String source) => Maintenance.fromMap(json.decode(source));

  Maintenance copyWith({
    int? id,
    int? customerId,
    DateTime? installationDate,
    DateTime? nextMaintenanceDate,
    String? maintenanceType,
    MaintenanceStatus? status,
    String? notes,
    DateTime? completedDate,
    String? issue,
    String? fix,
    double? cost,
  }) {
    return Maintenance(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      installationDate: installationDate ?? this.installationDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      completedDate: completedDate ?? this.completedDate,
      issue: issue ?? this.issue,
      fix: fix ?? this.fix,
      cost: cost ?? this.cost,
    );
  }
}