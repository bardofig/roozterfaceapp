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
  });

  // Método para crear una instancia de UserModel desde un snapshot de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
    );
  }

  // Método para convertir el objeto a un mapa para guardarlo en Firestore
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
    };
  }
}
