import 'dart:convert';

enum MaintenanceStatus { upcoming, completed, overdue }

class Maintenance {
  final int? id;
  final int machineryId;
  final DateTime dueDate;
  final DateTime? nextMaintenanceDate;
  final String maintenanceType; // Type of maintenance being performed
  final MaintenanceStatus status;
  final String? notes;
  final DateTime? completedDate;
  final String? issue;      // Issue found during maintenance
  final String? fix;        // Fix applied during maintenance
  final double? cost;       // Cost of the maintenance/repair
  final DateTime? createdAt;

  Maintenance({
    this.id,
    required this.machineryId,
    required this.dueDate,
    this.nextMaintenanceDate,
    required this.maintenanceType,
    required this.status,
    this.notes,
    this.completedDate,
    this.issue,
    this.fix,
    this.cost,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'machineryId': machineryId,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'nextMaintenanceDate': nextMaintenanceDate?.millisecondsSinceEpoch,
      'maintenanceType': maintenanceType,
      'status': status.toString().split('.').last,
      'notes': notes,
      'completedDate': completedDate?.millisecondsSinceEpoch,
      'issue': issue,
      'fix': fix,
      'cost': cost,
      'createdAt': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory Maintenance.fromMap(Map<String, dynamic> map) {
    return Maintenance(
      id: map['id'],
      machineryId: map['machineryId'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      nextMaintenanceDate: map['nextMaintenanceDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextMaintenanceDate'])
          : null,
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
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Maintenance.fromJson(String source) => Maintenance.fromMap(json.decode(source));

  Maintenance copyWith({
    int? id,
    int? machineryId,
    DateTime? dueDate,
    DateTime? nextMaintenanceDate,
    String? maintenanceType,
    MaintenanceStatus? status,
    String? notes,
    DateTime? completedDate,
    String? issue,
    String? fix,
    double? cost,
    DateTime? createdAt,
  }) {
    return Maintenance(
      id: id ?? this.id,
      machineryId: machineryId ?? this.machineryId,
      dueDate: dueDate ?? this.dueDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      completedDate: completedDate ?? this.completedDate,
      issue: issue ?? this.issue,
      fix: fix ?? this.fix,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}