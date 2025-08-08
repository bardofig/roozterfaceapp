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

  // --- ¡NUEVOS CAMPOS PARA VENTAS! ---
  final double? salePrice; // Precio de venta
  final Timestamp? saleDate; // Fecha de venta
  final String? buyerName; // Nombre del comprador

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
    );
  }

  // Método para convertir los datos a un mapa para guardarlos en Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name, 'plate': plate, 'status': status,
      'birthDate': birthDate, 'imageUrl': imageUrl,
      'fatherId': fatherId, 'fatherName': fatherName,
      'motherId': motherId, 'motherName': motherName,
      'fatherLineageText': fatherLineageText,
      'motherLineageText': motherLineageText,
      'breedLine': breedLine, 'color': color,
      'combType': combType, 'legColor': legColor,
      'salePrice': salePrice, 'saleDate': saleDate, 'buyerName': buyerName,
      'createdAt':
          FieldValue.serverTimestamp(), // Aseguramos que este campo se mantenga
    };
  }
}
