// lib/providers/gallera_data_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/services/gallera_service.dart';

class GalleraDataProvider with ChangeNotifier {
  final GalleraService _galleraService = GalleraService();
  DocumentSnapshot? _galleraData;
  bool _isLoading = true;

  DocumentSnapshot? get galleraData => _galleraData;
  bool get isLoading => _isLoading;

  // Depende del UserDataProvider para obtener el activeGalleraId
  GalleraDataProvider(UserDataProvider? userDataProvider) {
    if (userDataProvider?.userProfile?.activeGalleraId != null) {
      _listenToGalleraData(userDataProvider!.userProfile!.activeGalleraId!);
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToGalleraData(String galleraId) {
    _galleraService
        .getGalleraStream(galleraId)
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              _galleraData = snapshot;
            } else {
              _galleraData = null;
            }
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            print("Error en GalleraDataProvider: $error");
            _galleraData = null;
            _isLoading = false;
            notifyListeners();
          },
        );
  }
}
