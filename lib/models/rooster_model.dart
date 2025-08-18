// lib/models/rooster_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RoosterModel {
  final String id;
  final String name;
  final String plate;
  final String status;
  final Timestamp birthDate;
  final String imageUrl;

  // --- ¡NUEVO CAMPO FUNDAMENTAL! ---
  final String sex; // "macho" o "hembra"

  // Linaje
  final String? fatherId;
  final String? fatherName;
  final String? motherId;
  final String? motherName;
  final String? fatherLineageText;
  final String? motherLineageText;

  // Características
  final String? breedLine;
  final String? color;
  final String? combType;
  final String? legColor;

  // Venta
  final double? salePrice;
  final Timestamp? saleDate;
  final String? buyerName;
  final String? saleNotes;
  final bool? showInShowcase;

  // Físico y Ubicación
  final double? weight;
  final String? areaId;
  final String? areaName;

  RoosterModel({
    required this.id,
    required this.name,
    required this.plate,
    required this.status,
    required this.birthDate,
    required this.sex, // <-- AÑADIDO AL CONSTRUCTOR
    this.imageUrl = '',
    this.fatherId,
    this.fatherName,
    this.motherId,
    this.motherName,
    this.fatherLineageText,
    this.motherLineageText,
    this.breedLine,
    this.color,
    this.combType,
    this.legColor,
    this.salePrice,
    this.saleDate,
    this.buyerName,
    this.saleNotes,
    this.showInShowcase,
    this.weight,
    this.areaId,
    this.areaName,
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
      // Leemos el nuevo campo. Si no existe en un gallo antiguo, por defecto será "macho".
      sex: data['sex'] ?? 'macho',
      fatherId: data['fatherId'],
      fatherName: data['fatherName'],
      motherId: data['motherId'],
      motherName: data['motherName'],
      fatherLineageText: data['fatherLineageText'],
      motherLineageText: data['motherLineageText'],
      breedLine: data['breedLine'],
      color: data['color'],
      combType: data['combType'],
      legColor: data['legColor'],
      salePrice: (data['salePrice'] as num?)?.toDouble(),
      saleDate: data['saleDate'],
      buyerName: data['buyerName'],
      saleNotes: data['saleNotes'],
      showInShowcase: data['showInShowcase'],
      weight: (data['weight'] as num?)?.toDouble(),
      areaId: data['areaId'],
      areaName: data['areaName'],
    );
  }
}
