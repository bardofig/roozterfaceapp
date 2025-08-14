// lib/models/rooster_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RoosterModel {
  final String id;
  final String name;
  final String plate;
  final String status;
  final Timestamp birthDate;
  final String imageUrl;

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

  // --- ¡NUEVOS CAMPOS PARA VENTAS Y ESCAPARATE! ---
  final double? salePrice; // Precio de venta establecido
  final Timestamp? saleDate; // Fecha en la que se concretó la venta
  final String? buyerName; // Nombre del comprador
  final String? saleNotes; // Notas sobre la venta
  final bool? showInShowcase; // (Élite) ¿Se muestra en el escaparate público?

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
    this.breedLine,
    this.color,
    this.combType,
    this.legColor,
    // Añadimos al constructor
    this.salePrice,
    this.saleDate,
    this.buyerName,
    this.saleNotes,
    this.showInShowcase,
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
      breedLine: data['breedLine'],
      color: data['color'],
      combType: data['combType'],
      legColor: data['legColor'],
      // Leemos los nuevos campos
      salePrice: (data['salePrice'] as num?)?.toDouble(),
      saleDate: data['saleDate'],
      buyerName: data['buyerName'],
      saleNotes: data['saleNotes'],
      showInShowcase: data['showInShowcase'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'plate': plate,
      'status': status,
      'birthDate': birthDate,
      'imageUrl': imageUrl,
      'fatherId': fatherId,
      'fatherName': fatherName,
      'motherId': motherId,
      'motherName': motherName,
      'fatherLineageText': fatherLineageText,
      'motherLineageText': motherLineageText,
      'breedLine': breedLine,
      'color': color,
      'combType': combType,
      'legColor': legColor,
      'salePrice': salePrice,
      'saleDate': saleDate,
      'buyerName': buyerName,
      'saleNotes': saleNotes,
      'showInShowcase': showInShowcase,
      'lastUpdate': FieldValue.serverTimestamp(),
    };
  }
}
