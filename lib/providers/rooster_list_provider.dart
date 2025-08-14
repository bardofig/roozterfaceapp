// lib/providers/rooster_list_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';

class RoosterListProvider with ChangeNotifier {
  final RoosterService _roosterService = RoosterService();
  StreamSubscription? _roosterSubscription;

  List<RoosterModel> _roosters = [];
  bool _isLoading = true; // Inicia como cargando por defecto
  String? _currentGalleraId;

  List<RoosterModel> get roosters => _roosters;
  bool get isLoading => _isLoading;

  /// Ordena al proveedor buscar y escuchar la lista de gallos de una gallera específica.
  /// Si el galleraId es el mismo que ya está escuchando, no hace nada.
  void fetchRoosters(String? galleraId) {
    if (galleraId == _currentGalleraId) {
      return; // Ya estamos escuchando a esta gallera, no hay acción necesaria.
    }

    _currentGalleraId = galleraId;
    _roosterSubscription
        ?.cancel(); // Siempre cancelamos la suscripción anterior

    if (_currentGalleraId == null || _currentGalleraId!.isEmpty) {
      // Caso: No hay gallera activa (ej. el usuario acaba de ser eliminado de una)
      _roosters = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Iniciamos la nueva operación de carga
    _isLoading = true;
    notifyListeners();

    _roosterSubscription = _roosterService
        .getRoostersStream(_currentGalleraId!)
        .listen((roostersData) {
      _roosters = roostersData;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      print("Error catastrófico en RoosterListProvider: $error");
      _roosters = []; // En caso de error (ej. permisos), vaciamos la lista
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _roosterSubscription?.cancel();
    super.dispose();
  }
}
