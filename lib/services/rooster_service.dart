// lib/services/rooster_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/models/user_model.dart';

class RoosterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;

  CollectionReference _roostersCollection(String galleraId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('gallos');
  }

  Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
    }
    return null;
  }

  Stream<DocumentSnapshot> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid).snapshots();
    } else {
      return const Stream.empty();
    }
  }

  Stream<List<RoosterModel>> getRoostersStream(String galleraId) {
    if (galleraId.isEmpty) return Stream.value([]);
    return _roostersCollection(galleraId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoosterModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<RoosterModel?> getRoosterById(
    String galleraId,
    String roosterId,
  ) async {
    if (galleraId.isEmpty) return null;
    try {
      final docSnapshot =
          await _roostersCollection(galleraId).doc(roosterId).get();
      if (docSnapshot.exists) {
        return RoosterModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print("Error al obtener el gallo por ID ($roosterId): $e");
      return null;
    }
  }

  Future<List<RoosterModel>> getRoostersByIds(
      String galleraId, List<String> roosterIds) async {
    if (galleraId.isEmpty || roosterIds.isEmpty) return [];
    try {
      final querySnapshot = await _roostersCollection(galleraId)
          .where(FieldPath.documentId, whereIn: roosterIds)
          .get();
      return querySnapshot.docs
          .map((doc) => RoosterModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error al obtener gallos por IDs: $e");
      return [];
    }
  }

  Future<void> addNewRooster({
    required String galleraId,
    required String name,
    required String plate,
    required String status,
    required DateTime birthDate,
    required File imageFile,
    String? fatherId,
    String? fatherName,
    String? motherId,
    String? motherName,
    String? fatherLineageText,
    String? motherLineageText,
    String? breedLine,
    String? color,
    String? combType,
    String? legColor,
    double? salePrice,
    bool? showInShowcase,
  }) async {
    if (currentUserId == null) throw Exception("Usuario no autenticado.");
    String filePath =
        'users/$currentUserId/galleras/$galleraId/gallos/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference photoRef = _storage.ref().child(filePath);
    try {
      UploadTask uploadTask = photoRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      Map<String, dynamic> roosterData = {
        'name': name,
        'plate': plate,
        'status': status,
        'birthDate': Timestamp.fromDate(birthDate),
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdate': FieldValue.serverTimestamp(),
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
        'showInShowcase': showInShowcase ?? false,
        'saleDate': null,
        'buyerName': null,
        'saleNotes': null,
      };
      await _roostersCollection(galleraId).add(roosterData);
    } catch (e) {
      try {
        await photoRef.delete();
      } catch (deleteError) {
        print("Error en compensación: $deleteError");
      }
      throw Exception("Ocurrió un error al guardar los datos.");
    }
  }

  Future<void> updateRooster({
    required String galleraId,
    required String roosterId,
    required String name,
    required String plate,
    required String status,
    required DateTime birthDate,
    File? newImageFile,
    String? existingImageUrl,
    String? fatherId,
    String? fatherName,
    String? motherId,
    String? motherName,
    String? fatherLineageText,
    String? motherLineageText,
    String? breedLine,
    String? color,
    String? combType,
    String? legColor,
    double? salePrice,
    DateTime? saleDate,
    String? buyerName,
    String? saleNotes,
    bool? showInShowcase,
  }) async {
    if (currentUserId == null) throw Exception("Usuario no autenticado.");
    String imageUrl = existingImageUrl ?? '';
    Reference? newPhotoRef;
    try {
      if (newImageFile != null) {
        String filePath =
            'users/$currentUserId/galleras/$galleraId/gallos/${DateTime.now().millisecondsSinceEpoch}.jpg';
        newPhotoRef = _storage.ref().child(filePath);
        UploadTask uploadTask = newPhotoRef.putFile(newImageFile);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }
      Map<String, dynamic> updatedData = {
        'name': name,
        'plate': plate,
        'status': status,
        'birthDate': Timestamp.fromDate(birthDate),
        'imageUrl': imageUrl,
        'lastUpdate': FieldValue.serverTimestamp(),
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
        'saleDate': saleDate != null ? Timestamp.fromDate(saleDate) : null,
        'buyerName': buyerName,
        'saleNotes': saleNotes,
        'showInShowcase': showInShowcase,
      };

      updatedData.removeWhere((key, value) => value == null);

      await _roostersCollection(galleraId).doc(roosterId).update(updatedData);
      if (newImageFile != null &&
          existingImageUrl != null &&
          existingImageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(existingImageUrl).delete();
        } catch (e) {
          print("No se pudo borrar imagen antigua: $e");
        }
      }
    } catch (e) {
      if (newPhotoRef != null) {
        await newPhotoRef.delete();
      }
      throw Exception("Ocurrió un error al actualizar los datos.");
    }
  }

  Future<void> deleteRooster({
    required String galleraId,
    required RoosterModel rooster,
  }) async {
    if (rooster.imageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(rooster.imageUrl).delete();
      } catch (e) {
        print("Error al borrar imagen de Storage: $e");
      }
    }
    await _roostersCollection(galleraId).doc(rooster.id).delete();
  }

  // Obtiene el historial de gallos marcados como "Vendido"
  Stream<List<RoosterModel>> getSalesHistoryStream(String galleraId) {
    if (galleraId.isEmpty) return Stream.value([]);
    return _roostersCollection(galleraId)
        .where('status', isEqualTo: 'Vendido')
        .orderBy('saleDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoosterModel.fromFirestore(doc))
            .toList());
  }

  // Obtiene los gallos marcados para mostrar en el escaparate público
  Stream<List<RoosterModel>> getShowcaseRoostersStream(String galleraId) {
    if (galleraId.isEmpty) return Stream.value([]);
    return _roostersCollection(galleraId)
        .where('status', isEqualTo: 'En Venta')
        .where('showInShowcase', isEqualTo: true)
        .orderBy('lastUpdate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoosterModel.fromFirestore(doc))
            .toList());
  }
}
