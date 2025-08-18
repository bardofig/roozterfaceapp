// lib/models/area_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AreaModel {
  final String id;
  final String name;
  final String category;
  final String? description;

  const AreaModel({
    required this.id,
    required this.name,
    required this.category,
    this.description,
  });

  factory AreaModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AreaModel(
      id: doc.id,
      name: data['name'] ?? 'Área sin nombre',
      category: data['category'] ?? 'Otra',
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
    };
  }
}
