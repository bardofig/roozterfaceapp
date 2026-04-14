// lib/services/rooster_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // ✅ Agregado
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/financial_service.dart'; // ✅ AGREGADO
import 'package:roozterfaceapp/models/user_model.dart';

class RoosterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FinancialService _financialService = FinancialService(); // ✅ AGREGADO

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;

  CollectionReference _roostersCollection(String galleraId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('gallos');
  }

  /// Comprime una imagen para reducir su tamaño antes de subirla a Firebase Storage.
  /// Reduce el tamaño en aproximadamente 70-85% manteniendo buena calidad.
  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf('.');
      final outPath = '\${filePath.substring(0, lastIndex)}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: 85, // Calidad 85% - buen balance entre tamaño y calidad
        minWidth: 1024, // Ancho máximo 1024px
        minHeight: 1024, // Alto máximo 1024px
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      print("Error al comprimir imagen: \$e");
      return file; // Si falla la compresión, usar imagen original
    }
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

  /// Obtiene una página de gallos para scroll infinito.
  Future<QuerySnapshot> getRoostersPage({
    required String galleraId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    if (galleraId.isEmpty) {
      throw Exception("Gallera ID no puede estar vacío");
    }

    Query query = _roostersCollection(galleraId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.get();
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

  Future<RoosterModel> addNewRooster({
    required String galleraId,
    required String name,
    required String plate,
    required String status,
    required DateTime birthDate,
    required String sex,
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
    double? weight,
    String? areaId,
    String? areaName,
    List<File>? additionalImages, // <-- NUEVO PARÁMETRO
  }) async {
    if (currentUserId == null) throw Exception("Usuario no autenticado.");
    
    // ✅ Comprimir imagen antes de subir
    final compressedImage = await _compressImage(imageFile);
    if (compressedImage == null) {
      throw Exception("Error al procesar la imagen.");
    }
    
    String filePath =
        'users/$currentUserId/gallos/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference photoRef = _storage.ref().child(filePath);
    try {
      UploadTask uploadTask = photoRef.putFile(compressedImage); // ✅ Usar imagen comprimida
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // ✅ Subir fotos adicionales si existen
      List<String> additionalPhotoUrls = [];
      if (additionalImages != null && additionalImages.isNotEmpty) {
        additionalPhotoUrls = await _uploadAdditionalPhotos(additionalImages);
      }

      Map<String, dynamic> roosterData = {
        'name': name,
        'plate': plate,
        'status': status,
        'birthDate': Timestamp.fromDate(birthDate),
        'imageUrl': downloadUrl,
        'sex': sex,
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
        'weight': weight,
        'areaId': areaId,
        'areaName': areaName,
        'additionalPhotos': additionalPhotoUrls, // <-- GUARDAR URLs
      };

      DocumentReference ref =
          await _roostersCollection(galleraId).add(roosterData);

      return RoosterModel(
        id: ref.id,
        name: name,
        plate: plate,
        status: status,
        birthDate: Timestamp.fromDate(birthDate),
        sex: sex,
        imageUrl: downloadUrl,
        fatherId: fatherId,
        fatherName: fatherName,
        motherId: motherId,
        motherName: motherName,
        fatherLineageText: fatherLineageText,
        motherLineageText: motherLineageText,
        breedLine: breedLine,
        color: color,
        combType: combType,
        legColor: legColor,
        salePrice: salePrice,
        saleDate: null,
        buyerName: null,
        saleNotes: null,
        showInShowcase: showInShowcase ?? false,
        weight: weight,
        areaId: areaId,
        areaName: areaName,
        additionalPhotos: additionalPhotoUrls, // <-- AGREGADO
      );
    } catch (e) {
      try {
        await photoRef.delete();
      } catch (deleteError) {
        print("Error en compensación: $deleteError");
      }
      throw Exception("Ocurrió un error al guardar los datos: ${e.toString()}");
    }
  }

  // ✅ HELPER PARA SUBIOR MÚLTIPLES FOTOS CON COMPRESIÓN
  Future<List<String>> _uploadAdditionalPhotos(List<File> images) async {
    List<String> urls = [];
    for (var image in images) {
      final compressed = await _compressImage(image);
      if (compressed == null) continue;

      String path =
          'users/$currentUserId/gallos/extras/${DateTime.now().millisecondsSinceEpoch}_${images.indexOf(image)}.jpg';
      Reference ref = _storage.ref().child(path);
      UploadTask task = ref.putFile(compressed);
      TaskSnapshot snap = await task;
      String url = await snap.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<RoosterModel> updateRooster({
    required String galleraId,
    required String roosterId,
    required String name,
    required String plate,
    required String status,
    required DateTime birthDate,
    required String sex,
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
    double? weight,
    String? areaId,
    String? areaName,
    List<File>? newAdditionalImages, // <-- NUEVO PARÁMETRO
    List<String>? existingAdditionalPhotos, // <-- NUEVO PARÁMETRO
  }) async {
    if (currentUserId == null) throw Exception("Usuario no autenticado.");
    String imageUrl = existingImageUrl ?? '';
    Reference? newPhotoRef;
    try {
      if (newImageFile != null) {
        // ✅ Comprimir imagen antes de subir
        final compressedImage = await _compressImage(newImageFile);
        if (compressedImage == null) {
          throw Exception("Error al procesar la imagen.");
        }
        
        String filePath =
            'users/$currentUserId/gallos/${DateTime.now().millisecondsSinceEpoch}.jpg';
        newPhotoRef = _storage.ref().child(filePath);
        UploadTask uploadTask = newPhotoRef.putFile(compressedImage); // ✅ Usar imagen comprimida
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // ✅ Manejar fotos adicionales
      List<String> finalAdditionalPhotos =
          List<String>.from(existingAdditionalPhotos ?? []);

      if (newAdditionalImages != null && newAdditionalImages.isNotEmpty) {
        final newUrls = await _uploadAdditionalPhotos(newAdditionalImages);
        finalAdditionalPhotos.addAll(newUrls);
      }

      final updatedRooster = RoosterModel(
        id: roosterId,
        name: name,
        plate: plate,
        status: status,
        birthDate: Timestamp.fromDate(birthDate),
        sex: sex,
        imageUrl: imageUrl,
        fatherId: fatherId,
        fatherName: fatherName,
        motherId: motherId,
        motherName: motherName,
        fatherLineageText: fatherLineageText,
        motherLineageText: motherLineageText,
        breedLine: breedLine,
        color: color,
        combType: combType,
        legColor: legColor,
        salePrice: salePrice,
        saleDate: saleDate != null ? Timestamp.fromDate(saleDate) : null,
        buyerName: buyerName,
        saleNotes: saleNotes,
        showInShowcase: showInShowcase ?? false,
        weight: weight,
        areaId: areaId,
        areaName: areaName,
        additionalPhotos: finalAdditionalPhotos, // <-- AGREGADO
      );

      final updatedData = updatedRooster.toMap();
      updatedData['lastUpdate'] = FieldValue.serverTimestamp();

      await _roostersCollection(galleraId).doc(roosterId).update(updatedData);

      // Limpiar la imagen antigua de Storage si se subió una nueva
      if (newImageFile != null &&
          existingImageUrl != null &&
          existingImageUrl.isNotEmpty) {
        try {
          if (existingImageUrl.contains('firebasestorage.googleapis.com')) {
            await _storage.refFromURL(existingImageUrl).delete();
          }
        } catch (e) {
          print("No se pudo borrar imagen antigua: $e");
        }
      }

      return updatedRooster;
    } catch (e) {
      if (newPhotoRef != null) {
        await newPhotoRef.delete();
      }
      throw Exception(
          "Ocurrió un error al actualizar los datos: ${e.toString()}");
    }
  }

  /// --- ¡NUEVA FUNCIÓN! ---
  /// Registra la venta de un gallo, actualizando su estado y detalles de venta.
  /// Esto disparará la Cloud Function 'onRoosterUpdate' para crear la transacción.
  Future<void> recordSale({
    required String galleraId,
    required String roosterId,
    required double salePrice,
    required DateTime saleDate,
    required String buyerName,
    String? saleNotes,
  }) async {
    if (salePrice <= 0) {
      throw Exception("El precio de venta debe ser un número positivo.");
    }

    final Map<String, dynamic> saleData = {
      'status': 'Vendido',
      'salePrice': salePrice,
      'saleDate': Timestamp.fromDate(saleDate),
      'buyerName': buyerName,
      'saleNotes': saleNotes ?? '',
      'showInShowcase': false, // Un gallo vendido ya no está en el escaparate
      'lastUpdate': FieldValue.serverTimestamp(),
    };

    await _roostersCollection(galleraId).doc(roosterId).update(saleData);

    // ✅ REGISTRO AUTOMÁTICO EN FINANZAS
    await _financialService.addTransaction(
      galleraId: galleraId,
      type: 'ingreso',
      category: 'venta',
      amount: salePrice,
      description: 'Venta de ejemplar (ID: $roosterId) a $buyerName',
      date: saleDate,
      relatedId: roosterId,
    );
  }

  Future<void> deleteRooster({
    required String galleraId,
    required RoosterModel rooster,
  }) async {
    if (rooster.imageUrl.isNotEmpty) {
      try {
        if (rooster.imageUrl.contains('firebasestorage.googleapis.com')) {
          await _storage.refFromURL(rooster.imageUrl).delete();
        }
      } catch (e) {
        print("Error al borrar imagen de Storage: $e");
      }
    }
    await _roostersCollection(galleraId).doc(rooster.id).delete();
  }

  Stream<List<RoosterModel>> getSalesHistoryStream(String galleraId) {
    if (galleraId.isEmpty) return Stream.value([]);
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final startOfYearTimestamp = Timestamp.fromDate(startOfYear);
    return _roostersCollection(galleraId)
        .where('status', isEqualTo: 'Vendido')
        .where('saleDate', isGreaterThanOrEqualTo: startOfYearTimestamp)
        .orderBy('saleDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoosterModel.fromFirestore(doc))
            .toList());
  }

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

  /// --- ¡NUEVA FUNCIÓN! ---
  /// Registra un nuevo pesaje en el historial del gallo y actualiza su peso actual.
  Future<void> addWeightRecord({
    required String galleraId,
    required String roosterId,
    required double newWeight,
    DateTime? date,
    String? notes,
  }) async {
    final recordDate = date ?? DateTime.now();
    final Map<String, dynamic> newRecord = {
      'date': Timestamp.fromDate(recordDate),
      'weight': newWeight,
      'notes': notes ?? '',
    };

    // Actualizamos tanto el peso actual como el historial en una sola operación
    await _roostersCollection(galleraId).doc(roosterId).update({
      'weight': newWeight,
      'weightHistory': FieldValue.arrayUnion([newRecord]),
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// --- ¡NUEVA FUNCIÓN! ---
  /// Actualiza el área asignada a un gallo.
  Future<void> updateRoosterArea({
    required String galleraId,
    required String roosterId,
    required String? areaId,
    required String? areaName,
  }) async {
    await _roostersCollection(galleraId).doc(roosterId).update({
      'areaId': areaId,
      'areaName': areaName,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }
}
