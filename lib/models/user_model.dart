// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String mobilePhone;
  final String street;
  final String number;
  final String betweenStreets;
  final String postalCode;
  final String neighborhood;
  final String city;
  final String country;
  final String plan;
  final String? activeGalleraId;

  // --- ¡NUEVO CAMPO! ---
  // Lista de IDs de las galleras a las que pertenece o es miembro
  final List<String> galleraIds;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.mobilePhone,
    required this.street,
    required this.number,
    required this.betweenStreets,
    required this.postalCode,
    required this.neighborhood,
    required this.city,
    required this.country,
    this.plan = 'iniciacion',
    this.activeGalleraId,
    this.galleraIds = const [], // Valor por defecto: lista vacía
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // Convertimos la lista de Firestore a una lista de Strings
    List<String> galleras = List<String>.from(data['galleraIds'] ?? []);

    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      mobilePhone: data['mobilePhone'] ?? '',
      street: data['street'] ?? '',
      number: data['number'] ?? '',
      betweenStreets: data['betweenStreets'] ?? '',
      postalCode: data['postalCode'] ?? '',
      neighborhood: data['neighborhood'] ?? '',
      city: data['city'] ?? '',
      country: data['country'] ?? '',
      plan: data['plan'] ?? 'iniciacion',
      activeGalleraId: data['activeGalleraId'],
      galleraIds: galleras,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'mobilePhone': mobilePhone,
      'street': street,
      'number': number,
      'betweenStreets': betweenStreets,
      'postalCode': postalCode,
      'neighborhood': neighborhood,
      'city': city,
      'country': country,
      'plan': plan,
      'activeGalleraId': activeGalleraId,
      'galleraIds': galleraIds,
    };
  }
}
