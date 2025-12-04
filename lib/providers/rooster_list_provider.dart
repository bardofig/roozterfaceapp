import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';

class RoosterListProvider with ChangeNotifier {
  final RoosterService _roosterService = RoosterService();
  
  // Estado de datos
  List<RoosterModel> _roosters = [];
  
  // Estado de paginación
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _currentGalleraId;
  
  // Flag de seguridad
  bool _isDisposed = false;

  // Getters
  List<RoosterModel> get roosters => _roosters;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get currentGalleraId => _currentGalleraId;

  /// Carga inicial de gallos (Primera página)
  Future<void> fetchRoosters(String? galleraId, {bool refresh = false}) async {
    if (galleraId == null || galleraId.isEmpty) {
      _roosters = [];
      notifyListeners();
      return;
    }

    // Si es la misma gallera y no es refresh, y ya tenemos datos, no hacemos nada
    if (!refresh && galleraId == _currentGalleraId && _roosters.isNotEmpty) {
      return;
    }

    _currentGalleraId = galleraId;
    _isLoading = true;
    _hasMore = true;
    _lastDocument = null;
    
    // Notificar inicio de carga si no estamos en medio de un build
    if (!_isDisposed) notifyListeners();

    try {
      final snapshot = await _roosterService.getRoostersPage(
        galleraId: _currentGalleraId!,
        limit: 20,
      );

      if (_isDisposed) return;

      _roosters = snapshot.docs
          .map((doc) => RoosterModel.fromFirestore(doc))
          .toList();
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      
      // Si recibimos menos documentos que el límite, no hay más
      if (snapshot.docs.length < 20) {
        _hasMore = false;
      }

      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      
    } catch (e) {
      print("Error fetching roosters: $e");
      if (_isDisposed) return;
      _isLoading = false;
      _hasMore = false;
      notifyListeners();
    }
  }

  /// Carga la siguiente página de gallos
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _currentGalleraId == null) return;

    _isLoadingMore = true;
    if (!_isDisposed) notifyListeners();

    try {
      final snapshot = await _roosterService.getRoostersPage(
        galleraId: _currentGalleraId!,
        limit: 20,
        startAfter: _lastDocument,
      );

      if (_isDisposed) return;

      final newRoosters = snapshot.docs
          .map((doc) => RoosterModel.fromFirestore(doc))
          .toList();

      _roosters.addAll(newRoosters);
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      if (snapshot.docs.length < 20) {
        _hasMore = false;
      }

      _isLoadingMore = false;
      if (!_isDisposed) notifyListeners();

    } catch (e) {
      print("Error loading more roosters: $e");
      if (_isDisposed) return;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  /// Método auxiliar para actualizar la lista localmente (ej: tras agregar un gallo)
  /// Esto evita tener que recargar toda la lista desde el servidor
  void addRoosterLocally(RoosterModel rooster) {
    _roosters.insert(0, rooster);
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
