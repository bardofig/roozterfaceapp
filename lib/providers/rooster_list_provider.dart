// lib/providers/rooster_list_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';

class RoosterListProvider with ChangeNotifier {
  final RoosterService _roosterService = RoosterService();
  StreamSubscription? _roosterSubscription;

  List<RoosterModel> _roosters = [];
  bool _isLoading = true; // Inicia como 'true' por defecto
  String? _currentGalleraId;

  // --- Getters públicos
  List<RoosterModel> get roosters => _roosters;
  bool get isLoading => _isLoading;
  String? get currentGalleraId => _currentGalleraId;

  void fetchRoosters(String? galleraId) {
    // Si la gallera es la misma, no hacemos nada.
    if (galleraId == _currentGalleraId) {
      return;
    }

    _currentGalleraId = galleraId;
    _roosterSubscription?.cancel();

    // Caso: No hay gallera activa.
    if (_currentGalleraId == null || _currentGalleraId!.isEmpty) {
      _roosters = [];
      // Nos aseguramos de que el indicador de carga se quite.
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    // --- PUNTO CRÍTICO DE LA CORRECCIÓN ---
    // ANTES de suscribirnos al nuevo stream, ANUNCIAMOS que una nueva carga va a comenzar.
    // Esto asegura que la HomeScreen muestre el indicador de carga ANTES de recibir la lista.
    _isLoading = true;
    _roosters =
        []; // Vaciamos la lista vieja para que no se muestren datos incorrectos mientras carga.
    notifyListeners(); // FORZAMOS la reconstrucción de la UI al estado de carga.

    _roosterSubscription = _roosterService
        .getRoostersStream(_currentGalleraId!)
        .listen((roostersData) {
      _roosters = roostersData;
      _isLoading =
          false; // Al recibir datos (incluso una lista vacía), ANUNCIAMOS que la carga ha terminado.
      notifyListeners(); // Notificamos a la UI para que se reconstruya con los nuevos datos Y SIN el indicador.
    }, onError: (error) {
      print("Error en el stream de RoosterListProvider: $error");
      _roosters = [];
      _isLoading = false; // También terminamos la carga si hay un error.
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _roosterSubscription?.cancel();
    super.dispose();
  }
}
