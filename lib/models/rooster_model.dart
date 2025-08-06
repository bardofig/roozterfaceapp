// lib/models/rooster_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RoosterModel {
  final String id;
  final String name;
  final String plate;
  final String status;
  final Timestamp birthDate;
  final String imageUrl;

  // Linaje por Selección y Texto
  final String? fatherId;
  final String? fatherName;
  final String? motherId;
  final String? motherName;
  final String? fatherLineageText;
  final String? motherLineageText;

  // --- ¡NUEVOS CAMPOS DE REFINAMIENTO! ---
  final String? breedLine; // Línea/Casta (ej: "Kelso", "Sweater")
  final String? color;
  final String? combType; // Tipo de cresta
  final String? legColor;

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
    // Añadimos los nuevos campos al constructor
    this.breedLine,
    this.color,
    this.combType,
    this.legColor,
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
      fatherLineageText: data['fatherLineageText'],
      motherLineageText: data['motherLineageText'],
      // Leemos los nuevos campos desde Firestore
      breedLine: data['breedLine'],
      color: data['color'],
      combType: data['combType'],
      legColor: data['legColor'],
    );
  }
}
