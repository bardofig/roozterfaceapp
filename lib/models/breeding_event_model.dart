// lib/models/breeding_event_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BreedingEventModel {
  final String id;
  final Timestamp eventDate;

  // Padres
  final String? fatherId;
  final String? fatherName;
  final String? fatherPlate;
  final String? motherId;
  final String? motherName;
  final String? motherPlate;
  final String? externalFatherLineage;
  final String? externalMotherLineage;

  final String notes;

  // --- ¡NUEVOS CAMPOS PARA LA GESTIÓN DE LA NIDADA! ---
  final int? eggCount; // Número de huevos puestos
  final Timestamp? incubationStartDate; // Fecha de inicio de incubación
  final int? chicksHatched; // Número de pollos nacidos
  final Timestamp? hatchDate; // Fecha real de eclosión
  final String? clutchNotes; // Notas específicas de la nidada

  BreedingEventModel({
    required this.id,
    required this.eventDate,
    this.fatherId,
    this.fatherName,
    this.fatherPlate,
    this.motherId,
    this.motherName,
    this.motherPlate,
    this.externalFatherLineage,
    this.externalMotherLineage,
    required this.notes,
    // Añadimos al constructor
    this.eggCount,
    this.incubationStartDate,
    this.chicksHatched,
    this.hatchDate,
    this.clutchNotes,
  });

  factory BreedingEventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BreedingEventModel(
      id: doc.id,
      eventDate: data['eventDate'] ?? Timestamp.now(),
      fatherId: data['fatherId'],
      fatherName: data['fatherName'],
      fatherPlate: data['fatherPlate'],
      motherId: data['motherId'],
      motherName: data['motherName'],
      motherPlate: data['motherPlate'],
      externalFatherLineage: data['externalFatherLineage'],
      externalMotherLineage: data['externalMotherLineage'],
      notes: data['notes'] ?? '',
      // Leemos los nuevos campos
      eggCount: data['eggCount'],
      incubationStartDate: data['incubationStartDate'],
      chicksHatched: data['chicksHatched'],
      hatchDate: data['hatchDate'],
      clutchNotes: data['clutchNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventDate': eventDate,
      'fatherId': fatherId,
      'fatherName': fatherName,
      'fatherPlate': fatherPlate,
      'motherId': motherId,
      'motherName': motherName,
      'motherPlate': motherPlate,
      'externalFatherLineage': externalFatherLineage,
      'externalMotherLineage': externalMotherLineage,
      'notes': notes,
      'eggCount': eggCount,
      'incubationStartDate': incubationStartDate,
      'chicksHatched': chicksHatched,
      'hatchDate': hatchDate,
      'clutchNotes': clutchNotes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
