// lib/screens/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/services/payment_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoadingProducts = true;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _paymentService.purchaseStatusNotifier.addListener(
      _onPurchaseStatusChanged,
    );
    _loadProducts();
  }

  @override
  void dispose() {
    _paymentService.purchaseStatusNotifier.removeListener(
      _onPurchaseStatusChanged,
    );
    super.dispose();
  }

  void _onPurchaseStatusChanged() {
    final status = _paymentService.purchaseStatusNotifier.value;
    final messenger = ScaffoldMessenger.of(context);

    if (status == PurchaseProcessStatus.completed) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('¡Suscripción activada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else if (status == PurchaseProcessStatus.restored) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('¡Suscripción restaurada con éxito!'),
          backgroundColor: Colors.blue,
        ),
      );
    } else if (status == PurchaseProcessStatus.error) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error. Por favor, inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });
    await _paymentService.loadProducts();
    if (mounted) {
      setState(() {
        _products = _paymentService.products;
        _isLoadingProducts = false;
      });
    }
  }

  void _handlePurchase(ProductDetails product) {
    _paymentService.buyProduct(product);
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el plan actual del usuario desde el provider
    final currentUserPlan =
        Provider.of<UserDataProvider>(context).userProfile?.plan ??
        'iniciacion';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes y Suscripción'),
        actions: [
          // --- ¡NUEVO BOTÓN DE RESTAURAR! ---
          TextButton(
            onPressed: () {
              _paymentService.restorePurchases();
            },
            child: Text(
              'Restaurar',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ValueListenableBuilder<PurchaseProcessStatus>(
        valueListenable: _paymentService.purchaseStatusNotifier,
        builder: (context, status, child) {
          final bool isPurchasing =
              status == PurchaseProcessStatus.pending ||
              status == PurchaseProcessStatus.verifying;

          return Stack(
            children: [
              _isLoadingProducts
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No hay planes disponibles en este momento. Asegúrate de haber configurado los productos en la Google Play Console.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _buildPlanList(currentUserPlan),
              if (isPurchasing)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          status == PurchaseProcessStatus.pending
                              ? 'Procesando con la tienda...'
                              : 'Verificando compra...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlanList(String currentUserPlan) {
    const Map<String, Map<String, dynamic>> planDetails = {
      'maestro_criador_mensual': {
        'name': 'Maestro Criador',
        'planId': 'maestro',
        'features': [
          'Hasta 150 gallos',
          'Módulo de Linaje',
          'Historial de Combate',
          'Bitácora de Salud',
        ],
      },
      'maestro_criador_anual': {
        'name': 'Maestro Criador',
        'planId': 'maestro',
        'features': [
          'Ahorro del 20% Anual',
          'Hasta 150 gallos',
          'Historial de Combate',
          'Bitácora de Salud',
        ],
      },
      'club_elite_mensual': {
        'name': 'Club de Élite',
        'planId': 'elite',
        'features': [
          'Gallos Ilimitados',
          'Acceso Multiusuario',
          'Árbol Genealógico',
          'Analítica Avanzada',
        ],
      },
      'club_elite_anual': {
        'name': 'Club de Élite',
        'planId': 'elite',
        'features': [
          'Ahorro del 25% Anual',
          'Todo lo de Maestro',
          'Acceso Multiusuario',
          'Árbol Genealógico',
        ],
      },
    };

    // Ordenamos los productos para una mejor presentación
    _products.sort((a, b) {
      final aIsElite = a.id.contains('elite');
      final bIsElite = b.id.contains('elite');
      final aIsAnual = a.id.contains('anual');
      final bIsAnual = b.id.contains('anual');

      if (aIsElite != bIsElite) return aIsElite ? 1 : -1;
      if (aIsAnual != bIsAnual) return aIsAnual ? 1 : -1;
      return 0;
    });

    List<Widget> planCards = _products.map((product) {
      final details = planDetails[product.id];
      if (details == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: _buildPlanCard(
          context,
          title: details['name'],
          price: product.price,
          features: details['features'],
          isCurrentPlan: currentUserPlan == details['planId'],
          isRecommended:
              details['planId'] == 'maestro' && product.id.contains('anual'),
          onTap: () => _handlePurchase(product),
        ),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildPlanCard(
            context,
            title: 'Iniciación',
            price: 'Gratis',
            features: [
              'Hasta 15 gallos',
              'Ficha de datos básicos',
              'Seguimiento de estado',
            ],
            isCurrentPlan: currentUserPlan == 'iniciacion',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          ...planCards,
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required List<String> features,
    bool isCurrentPlan = false,
    bool isRecommended = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardColor = isRecommended
        ? (isDark ? Colors.blue.shade900 : Colors.blue.shade800)
        : theme.cardColor;
    final Color textColor = isRecommended
        ? Colors.white
        : theme.colorScheme.onSurface;
    final Color checkColor = isRecommended ? Colors.white : Colors.green;
    final Color buttonBgColor = isRecommended
        ? Colors.white
        : (isDark ? Colors.grey.shade300 : Colors.black);
    final Color buttonTextColor = isRecommended
        ? Colors.blue.shade800
        : (isDark ? Colors.black : Colors.white);

    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: isCurrentPlan
            ? const BorderSide(color: Colors.green, width: 3)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(fontSize: 20, color: textColor.withOpacity(0.9)),
            ),
            Divider(height: 30, color: textColor.withOpacity(0.2)),
            ...features.map(
              (feature) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle_outline, color: checkColor),
                title: Text(feature, style: TextStyle(color: textColor)),
              ),
            ),
            const SizedBox(height: 20),
            isCurrentPlan
                ? const Chip(
                    label: Text('Plan Actual'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBgColor,
                      foregroundColor: buttonTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Mejorar Plan'),
                  ),
          ],
        ),
      ),
    );
  }
}
