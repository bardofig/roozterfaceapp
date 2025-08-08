// lib/services/payment_service.dart

import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

// --- ¡DEFINICIÓN AHORA PÚBLICA! ---
// Al estar fuera de la clase, cualquier archivo que importe este servicio
// podrá usar 'PurchaseProcessStatus'.
enum PurchaseProcessStatus { idle, pending, verifying, completed, error }

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
    if (!available) return;
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
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
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
        case PurchaseStatus.restored:
          if (purchaseDetails is GooglePlayPurchaseDetails) {
            purchaseStatusNotifier.value = PurchaseProcessStatus.verifying;
            _verifyAndroidPurchase(purchaseDetails);
          } else {
            if (purchaseDetails.pendingCompletePurchase) {
              _inAppPurchase.completePurchase(purchaseDetails);
            }
            purchaseStatusNotifier.value = PurchaseProcessStatus.completed;
          }
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

  Future<void> _verifyAndroidPurchase(
    GooglePlayPurchaseDetails purchaseDetails,
  ) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: "us-central1");
      final callable = functions.httpsCallable('validateAndroidPurchase');

      final results = await callable.call(<String, dynamic>{
        'packageName': 'com.codigobardo.roozterface',
        'subscriptionId': purchaseDetails.productID,
        'purchaseToken':
            purchaseDetails.verificationData.serverVerificationData,
      });

      if (results.data['success'] == true) {
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        purchaseStatusNotifier.value = PurchaseProcessStatus.completed;
      } else {
        purchaseStatusNotifier.value = PurchaseProcessStatus.error;
      }
    } catch (e) {
      print("Error al llamar a la Cloud Function: $e");
      purchaseStatusNotifier.value = PurchaseProcessStatus.error;
    }
  }

  List<ProductDetails> get products => _products;

  void dispose() {
    _subscription.cancel();
    purchaseStatusNotifier.dispose();
  }
}
