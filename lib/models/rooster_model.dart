// lib/models/rooster_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RoosterModel {
  final String id;
  final String name;
  final String plate;
  final String status;
  final Timestamp birthDate;
  final String imageUrl;

  // Linaje por Selección
  final String? fatherId;
  final String? fatherName;
  final String? motherId;
  final String? motherName;

  // --- ¡NUEVOS CAMPOS PARA TEXTO LIBRE! ---
  final String? fatherLineageText; // Para linaje paterno manual
  final String? motherLineageText; // Para linaje materno manual

  RoosterModel({
    required this.id,
    required this.name,
    required this.plate,
    required this.status,
    required this.birthDate,
    this.imageUrl = '',
    this.fatherId,
    this.fatherName,
    this.motherId,
    this.motherName,
    this.fatherLineageText,
    this.motherLineageText,
  });

  factory RoosterModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return RoosterModel(
      id: doc.id,
      name: data['name'] ?? 'Sin Nombre',
      plate: data['plate'] ?? 'Sin Placa',
      status: data['status'] ?? 'Desconocido',
      birthDate: data['birthDate'] ?? Timestamp.now(),
      imageUrl: data['imageUrl'] ?? '',
      fatherId: data['fatherId'],
      fatherName: data['fatherName'],
      motherId: data['motherId'],
      motherName: data['motherName'],
      // Leemos los nuevos campos
      fatherLineageText: data['fatherLineageText'],
      motherLineageText: data['motherLineageText'],
    );
  }
}
