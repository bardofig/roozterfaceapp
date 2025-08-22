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

  List<RoosterModel> get roosters => _roosters;
  bool get isLoading => _isLoading;
  String? get currentGalleraId => _currentGalleraId;

  void fetchRoosters(String? galleraId) {
    // Si la gallera que nos piden cargar ya es la que tenemos, no hacemos nada.
    if (galleraId == _currentGalleraId && !_isLoading) {
      return;
    }

    _currentGalleraId = galleraId;
    _roosterSubscription?.cancel();

    // Si no hay galleraId, limpiamos el estado y notificamos.
    if (_currentGalleraId == null || _currentGalleraId!.isEmpty) {
      _roosters = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // --- ¡LÓGICA DE CARGA CORREGIDA Y DISCIPLINADA! ---
    // 1. ANTES de hacer nada, anunciamos que estamos cargando.
    _isLoading = true;
    _roosters =
        []; // Vaciamos los datos antiguos para no mostrarlos incorrectamente.
    notifyListeners(); // Forzamos a la UI a mostrar el indicador de carga.

    // 2. AHORA, nos suscribimos al stream de datos.
    _roosterSubscription = _roosterService
        .getRoostersStream(_currentGalleraId!)
        .listen((roostersData) {
      // 3. Cuando llegan los datos, actualizamos el estado y anunciamos que terminamos.
      _roosters = roostersData;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      print("Error en el stream de RoosterListProvider: $error");
      // 4. Si hay un error, también terminamos la carga.
      _roosters = [];
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
