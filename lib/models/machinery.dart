import 'dart:convert';

class Machinery {
  final int? id;
  final int customerId;
  final String name;
  final String serialNumber;
  final DateTime installationDate;
  final double? installationCost;
  final int checkupInterval; // in months
  final bool isDeleted; // Flag to mark machinery as deleted

  Machinery({
    this.id,
    required this.customerId,
    required this.name,
    required this.serialNumber,
    required this.installationDate,
    this.installationCost,
    required this.checkupInterval,
    this.isDeleted = false, // Default to false
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'name': name,
      'serialNumber': serialNumber,
      'installationDate': installationDate.millisecondsSinceEpoch,
      'installationCost': installationCost,
      'checkupInterval': checkupInterval,
      'isDeleted': isDeleted ? 1 : 0, // SQLite doesn't have boolean, use int
    };
  }

  factory Machinery.fromMap(Map<String, dynamic> map) {
    return Machinery(
      id: map['id'],
      customerId: map['customerId'],
      name: map['name'],
      serialNumber: map['serialNumber'],
      installationDate: DateTime.fromMillisecondsSinceEpoch(map['installationDate']),
      installationCost: map['installationCost'],
      checkupInterval: map['checkupInterval'],
      isDeleted: map['isDeleted'] == 1, // Convert from integer to boolean
    );
  }

  String toJson() => json.encode(toMap());

  factory Machinery.fromJson(String source) => Machinery.fromMap(json.decode(source));

  Machinery copyWith({
    int? id,
    int? customerId,
    String? name,
    String? serialNumber,
    DateTime? installationDate,
    double? installationCost,
    int? checkupInterval,
    bool? isDeleted,
  }) {
    return Machinery(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      installationDate: installationDate ?? this.installationDate,
      installationCost: installationCost ?? this.installationCost,
      checkupInterval: checkupInterval ?? this.checkupInterval,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}