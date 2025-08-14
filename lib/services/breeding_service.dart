// lib/services/breeding_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roozterfaceapp/models/breeding_event_model.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';

class BreedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Apunta a la subcolección de eventos de cría DENTRO de una gallera.
  CollectionReference _breedingEventsCollection(String galleraId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('breeding_events');
  }

  // Obtiene TODOS los eventos de cría de una gallera, para la pantalla principal.
  Stream<List<BreedingEventModel>> getAllBreedingEventsStream({
    required String galleraId,
  }) {
    if (galleraId.isEmpty) return Stream.value([]);

    return _breedingEventsCollection(galleraId)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BreedingEventModel.fromFirestore(doc))
            .toList());
  }

  // Añade un nuevo evento de cría a la base de datos.
  // Acepta padres internos (RoosterModel) o externos (String) como opcionales.
  Future<void> addBreedingEvent({
    required String galleraId,
    required DateTime eventDate,
    required String notes,
    RoosterModel? father,
    RoosterModel? mother,
    String? externalFatherLineage,
    String? externalMotherLineage,
  }) async {
    // Verificación: al menos un padre y una madre deben ser proporcionados
    if ((father == null &&
            (externalFatherLineage == null || externalFatherLineage.isEmpty)) ||
        (mother == null &&
            (externalMotherLineage == null || externalMotherLineage.isEmpty))) {
      throw Exception(
          "Debe proporcionar un padre y una madre, ya sean internos o externos.");
    }

    final event = BreedingEventModel(
      id: '', // Firestore generará el ID
      eventDate: Timestamp.fromDate(eventDate),
      // Si hay un padre interno, usa sus datos. Si no, nulo.
      fatherId: father?.id,
      fatherName: father?.name,
      fatherPlate: father?.plate,
      // Si hay una madre interna, usa sus datos. Si no, nulo.
      motherId: mother?.id,
      motherName: mother?.name,
      motherPlate: mother?.plate,
      // Guarda los datos de los padres externos
      externalFatherLineage: externalFatherLineage,
      externalMotherLineage: externalMotherLineage,
      notes: notes,
    );
    await _breedingEventsCollection(galleraId).add(event.toMap());
  }

  // Borra un evento de cría.
  Future<void> deleteBreedingEvent({
    required String galleraId,
    required String eventId,
  }) async {
    await _breedingEventsCollection(galleraId).doc(eventId).delete();
  }

// --- ¡NUEVO MÉTODO PARA ACTUALIZAR UNA NIDADA! ---
  Future<void> updateClutchDetails({
    required String galleraId,
    required String eventId,
    int? eggCount,
    DateTime? incubationStartDate,
    int? chicksHatched,
    DateTime? hatchDate,
    String? clutchNotes,
  }) async {
    final Map<String, dynamic> dataToUpdate = {};

    if (eggCount != null) dataToUpdate['eggCount'] = eggCount;
    if (incubationStartDate != null)
      dataToUpdate['incubationStartDate'] =
          Timestamp.fromDate(incubationStartDate);
    if (chicksHatched != null) dataToUpdate['chicksHatched'] = chicksHatched;
    if (hatchDate != null)
      dataToUpdate['hatchDate'] = Timestamp.fromDate(hatchDate);
    if (clutchNotes != null) dataToUpdate['clutchNotes'] = clutchNotes;

    // Solo actualizamos si hay algo que cambiar
    if (dataToUpdate.isNotEmpty) {
      await _breedingEventsCollection(galleraId)
          .doc(eventId)
          .update(dataToUpdate);
    }
  }
}
