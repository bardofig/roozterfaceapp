// lib/services/rooster_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';

class RoosterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference _userRoostersCollection() {
    if (currentUserId == null) {
      throw Exception("Usuario no autenticado.");
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('gallos');
  }

  Stream<DocumentSnapshot> getUserProfileStream() {
    if (currentUserId == null) {
      return const Stream.empty();
    }
    return _firestore.collection('users').doc(currentUserId).snapshots();
  }

  Stream<List<RoosterModel>> getRoostersStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return _userRoostersCollection()
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RoosterModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> addNewRooster({
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
  }) async {
    String filePath =
        'users/$currentUserId/gallos/${DateTime.now().millisecondsSinceEpoch}.jpg';
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
        'fatherId': fatherId,
        'fatherName': fatherName,
        'motherId': motherId,
        'motherName': motherName,
        'fatherLineageText': fatherLineageText,
        'motherLineageText': motherLineageText,
      };
      await _userRoostersCollection().add(roosterData);
    } catch (e) {
      try {
        await photoRef.delete();
      } catch (deleteError) {
        print(
          "Error CRÍTICO durante la compensación: No se pudo borrar la imagen. Ref: $filePath. Error: $deleteError",
        );
      }
      throw Exception("Ocurrió un error al guardar los datos.");
    }
  }

  Future<void> updateRooster({
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
  }) async {
    String imageUrl = existingImageUrl ?? '';
    Reference? newPhotoRef;
    try {
      if (newImageFile != null) {
        String filePath =
            'users/$currentUserId/gallos/${DateTime.now().millisecondsSinceEpoch}.jpg';
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
        'fatherId': fatherId,
        'fatherName': fatherName,
        'motherId': motherId,
        'motherName': motherName,
        'fatherLineageText': fatherLineageText,
        'motherLineageText': motherLineageText,
      };
      await _userRoostersCollection().doc(roosterId).update(updatedData);
      if (newImageFile != null &&
          existingImageUrl != null &&
          existingImageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(existingImageUrl).delete();
        } catch (e) {
          print(
            "No se pudo borrar la imagen antigua, pero los datos se actualizaron: $e",
          );
        }
      }
    } catch (e) {
      if (newPhotoRef != null) {
        await newPhotoRef.delete();
      }
      throw Exception("Ocurrió un error al actualizar los datos.");
    }
  }

  Future<void> deleteRooster(RoosterModel rooster) async {
    if (rooster.imageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(rooster.imageUrl).delete();
      } catch (e) {
        print("Error al borrar imagen de Storage, puede que no exista: $e");
      }
    }
    await _userRoostersCollection().doc(rooster.id).delete();
  }
}
