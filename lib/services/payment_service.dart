// lib/services/payment_service.dart

import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

enum PurchaseProcessStatus {
  idle,
  pending,
  verifying,
  completed,
  error,
  restored,
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ValueNotifier<PurchaseProcessStatus> purchaseStatusNotifier =
      ValueNotifier(PurchaseProcessStatus.idle);

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final Set<String> _productIds = {
    'maestro_criador_mensual',
    'maestro_criador_anual',
    'club_elite_mensual',
    'club_elite_anual',
  };

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  void initialize() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        purchaseStatusNotifier.value = PurchaseProcessStatus.error;
      },
    );
  }

  Future<void> loadProducts() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print("La tienda de compras no está disponible.");
      _products = [];
      return;
    }
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      print("Productos no encontrados: ${response.notFoundIDs}");
    }
    _products = response.productDetails;
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );
    // Para suscripciones, se usa buyNonConsumable.
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // --- ¡NUEVO MÉTODO PARA RESTAURAR COMPRAS! ---
  Future<void> restorePurchases() async {
    purchaseStatusNotifier.value = PurchaseProcessStatus.pending;
    try {
      await _inAppPurchase.restorePurchases();
      // El resultado se manejará en el _listenToPurchaseUpdated,
      // que cambiará el estado a 'restored' o 'error'.
    } catch (e) {
      print("Error restaurando compras: $e");
      purchaseStatusNotifier.value = PurchaseProcessStatus.error;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          purchaseStatusNotifier.value = PurchaseProcessStatus.pending;
          break;
        case PurchaseStatus.error:
          print("Error en la compra: ${purchaseDetails.error}");
          purchaseStatusNotifier.value = PurchaseProcessStatus.error;
          if (purchaseDetails.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;
        case PurchaseStatus.purchased:
          _handlePurchase(purchaseDetails);
          break;
        case PurchaseStatus.restored:
          // Cuando una compra se restaura, la tratamos igual que una nueva compra
          // para revalidarla y actualizar el estado del usuario en nuestro backend.
          _handlePurchase(purchaseDetails);
          purchaseStatusNotifier.value = PurchaseProcessStatus.restored;
          break;
        case PurchaseStatus.canceled:
          purchaseStatusNotifier.value = PurchaseProcessStatus.idle;
          if (purchaseDetails.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;
      }
    }
  }

  // Método unificado para manejar tanto compras nuevas como restauradas
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails is GooglePlayPurchaseDetails) {
      purchaseStatusNotifier.value = PurchaseProcessStatus.verifying;
      await _verifyAndroidPurchase(purchaseDetails);
    } else {
      // Para otras plataformas o si no se necesita verificación de servidor
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
      purchaseStatusNotifier.value = PurchaseProcessStatus.completed;
    }
  }

  Future<void> _verifyAndroidPurchase(
    GooglePlayPurchaseDetails purchaseDetails,
  ) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: "us-central1");
      final callable = functions.httpsCallable('validateAndroidPurchase');

      await callable.call<dynamic>({
        'packageName': 'com.codigobardo.roozterface',
        'subscriptionId': purchaseDetails.productID,
        'purchaseToken':
            purchaseDetails.verificationData.serverVerificationData,
      });

      // La Cloud Function ahora actualiza el plan.
      // El UserDataProvider detectará el cambio y la UI se actualizará.
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
      purchaseStatusNotifier.value = PurchaseProcessStatus.completed;
    } catch (e) {
      print("Error al llamar a la Cloud Function de validación: $e");
      purchaseStatusNotifier.value = PurchaseProcessStatus.error;
    }
  }

  void dispose() {
    _subscription.cancel();
    purchaseStatusNotifier.dispose();
  }
}
