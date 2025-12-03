// lib/providers/rooster_list_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';

class RoosterListProvider with ChangeNotifier {
  final RoosterService _roosterService = RoosterService();
  StreamSubscription? _roosterSubscription;

  List<RoosterModel> _roosters = [];
  bool _isLoading = true;
  String? _currentGalleraId;

  List<RoosterModel> get roosters => _roosters;
  bool get isLoading => _isLoading;
  String? get currentGalleraId => _currentGalleraId;

  void fetchRoosters(String? galleraId) {
    if (galleraId == _currentGalleraId && !_isLoading) {
      return;
    }

    _currentGalleraId = galleraId;
    _roosterSubscription?.cancel();

    if (_currentGalleraId == null || _currentGalleraId!.isEmpty) {
      _roosters = [];
      _isLoading = false;
      // Usamos microtask para asegurar que la notificación no interfiera
      // con un ciclo de construcción en progreso.
      Future.microtask(() {
        notifyListeners();
      });
      return;
    }

    // --- LÓGICA DE CARGA REFINADA CON MICROTASKS ---
    // 1. Agenda la notificación de 'cargando' para el próximo ciclo de eventos.
    Future.microtask(() {
      _isLoading = true;
      _roosters = [];
      notifyListeners();
    });

    _roosterSubscription = _roosterService
        .getRoostersStream(_currentGalleraId!)
        .listen((roostersData) {
      // 2. Cuando llegan los datos, agenda la notificación de 'terminado'.
      Future.microtask(() {
        _roosters = roostersData;
        _isLoading = false;
        notifyListeners();
      });
    }, onError: (error) {
      print("Error en el stream de RoosterListProvider: $error");
      // 3. Si hay un error, también agenda la notificación de 'terminado'.
      Future.microtask(() {
        _roosters = [];
        _isLoading = false;
        notifyListeners();
      });
    });
  }

  @override
  void dispose() {
    _roosterSubscription?.cancel();
    super.dispose();
  }
}
