// lib/services/breeding_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roozterfaceapp/models/breeding_event_model.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';

class HenProductionStats {
  final int totalClutches;
  final int totalEggs;
  final int totalChicks;
  final double averageHatchRate;

  HenProductionStats({
    this.totalClutches = 0,
    this.totalEggs = 0,
    this.totalChicks = 0,
    this.averageHatchRate = 0.0,
  });
}

class BreedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _breedingEventsCollection(String galleraId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('breeding_events');
  }

  Future<HenProductionStats> getHenProductionStats({
    required String galleraId,
    required String henId,
  }) async {
    if (galleraId.isEmpty) return HenProductionStats();

    final querySnapshot = await _breedingEventsCollection(galleraId)
        .where('motherId', isEqualTo: henId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return HenProductionStats();
    }

    int totalClutches = querySnapshot.docs.length;
    int totalEggs = 0;
    int totalChicks = 0;

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        totalEggs += (data['eggCount'] as int? ?? 0);
        totalChicks += (data['chicksHatched'] as int? ?? 0);
      }
    }

    double averageHatchRate =
        (totalEggs > 0) ? (totalChicks / totalEggs) * 100 : 0.0;

    return HenProductionStats(
      totalClutches: totalClutches,
      totalEggs: totalEggs,
      totalChicks: totalChicks,
      averageHatchRate: averageHatchRate,
    );
  }

  Stream<List<BreedingEventModel>> getAllBreedingEventsStream(
      {required String galleraId}) {
    if (galleraId.isEmpty) return Stream.value([]);
    return _breedingEventsCollection(galleraId)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BreedingEventModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<BreedingEventModel>> getBreedingHistoryStream({
    required String galleraId,
    required String roosterId,
  }) {
    if (galleraId.isEmpty) return Stream.value([]);

    var fatherQuery = _breedingEventsCollection(galleraId)
        .where('fatherId', isEqualTo: roosterId);
    var motherQuery = _breedingEventsCollection(galleraId)
        .where('motherId', isEqualTo: roosterId);

    return Stream.fromFuture(
            Future.wait([fatherQuery.get(), motherQuery.get()]))
        .asyncMap((snapshots) {
      final combinedDocs = [...snapshots[0].docs, ...snapshots[1].docs];
      final uniqueDocs =
          {for (var doc in combinedDocs) doc.id: doc}.values.toList();
      final events = uniqueDocs
          .map((doc) => BreedingEventModel.fromFirestore(doc))
          .toList();
      events.sort((a, b) => b.eventDate.compareTo(a.eventDate));
      return events;
    });
  }

  Future<void> addBreedingEvent({
    required String galleraId,
    required DateTime eventDate,
    required String notes,
    RoosterModel? father,
    RoosterModel? mother,
    String? externalFatherLineage,
    String? externalMotherLineage,
  }) async {
    if ((father == null &&
            (externalFatherLineage == null ||
                externalFatherLineage.trim().isEmpty)) ||
        (mother == null &&
            (externalMotherLineage == null ||
                externalMotherLineage.trim().isEmpty))) {
      throw Exception(
          "Debe proporcionar un padre y una madre, ya sean internos o externos.");
    }

    final event = BreedingEventModel(
      id: '',
      eventDate: Timestamp.fromDate(eventDate),
      fatherId: father?.id,
      fatherName: father?.name,
      fatherPlate: father?.plate,
      motherId: mother?.id,
      motherName: mother?.name,
      motherPlate: mother?.plate,
      externalFatherLineage: externalFatherLineage,
      externalMotherLineage: externalMotherLineage,
      notes: notes,
    );
    await _breedingEventsCollection(galleraId).add(event.toMap());
  }

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
    if (dataToUpdate.isNotEmpty) {
      await _breedingEventsCollection(galleraId)
          .doc(eventId)
          .update(dataToUpdate);
    }
  }

  Future<void> deleteBreedingEvent({
    required String galleraId,
    required String eventId,
  }) async {
    await _breedingEventsCollection(galleraId).doc(eventId).delete();
  }
}
