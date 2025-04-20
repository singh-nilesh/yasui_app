import 'dart:convert';

class Customer {
  final int? id;
  final String name;
  final String contactPersonOwner;
  final String? contactPersonProductionManager;
  final String? contactPersonTechnicalManager;
  final String address;
  final String pinCode;
  final String city;
  final String state;
  final String? phone;
  final String mobile;
  final String? email;
  final String? locationCoords;
  final String checkupInterval;

  Customer({
    this.id,
    required this.name,
    required this.contactPersonOwner,
    this.contactPersonProductionManager,
    this.contactPersonTechnicalManager,
    required this.address,
    required this.pinCode,
    required this.city,
    required this.state,
    this.phone,
    required this.mobile,
    this.email,
    this.locationCoords,
    required this.checkupInterval,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPersonOwner': contactPersonOwner,
      'contactPersonProductionManager': contactPersonProductionManager,
      'contactPersonTechnicalManager': contactPersonTechnicalManager,
      'address': address,
      'pinCode': pinCode,
      'city': city,
      'state': state,
      'phone': phone,
      'mobile': mobile,
      'email': email,
      'locationCoords': locationCoords,
      'checkupInterval': checkupInterval,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      contactPersonOwner: map['contactPersonOwner'],
      contactPersonProductionManager: map['contactPersonProductionManager'],
      contactPersonTechnicalManager: map['contactPersonTechnicalManager'],
      address: map['address'],
      pinCode: map['pinCode'],
      city: map['city'],
      state: map['state'],
      phone: map['phone'],
      mobile: map['mobile'],
      email: map['email'],
      locationCoords: map['locationCoords'],
      checkupInterval: map['checkupInterval'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Customer.fromJson(String source) => Customer.fromMap(json.decode(source));

  Customer copyWith({
    int? id,
    String? name,
    String? contactPersonOwner,
    String? contactPersonProductionManager,
    String? contactPersonTechnicalManager,
    String? address,
    String? pinCode,
    String? city,
    String? state,
    String? phone,
    String? mobile,
    String? email,
    String? locationCoords,
    String? checkupInterval,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPersonOwner: contactPersonOwner ?? this.contactPersonOwner,
      contactPersonProductionManager: contactPersonProductionManager ?? this.contactPersonProductionManager,
      contactPersonTechnicalManager: contactPersonTechnicalManager ?? this.contactPersonTechnicalManager,
      address: address ?? this.address,
      pinCode: pinCode ?? this.pinCode,
      city: city ?? this.city,
      state: state ?? this.state,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      locationCoords: locationCoords ?? this.locationCoords,
      checkupInterval: checkupInterval ?? this.checkupInterval,
    );
  }
}