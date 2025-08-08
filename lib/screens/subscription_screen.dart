// lib/screens/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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
  String _currentUserPlan = 'iniciacion';

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

    if (status == PurchaseProcessStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Suscripción activada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else if (status == PurchaseProcessStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocurrió un error al procesar la compra. Inténtalo de nuevo.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadProducts() async {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Planes y Suscripción')),
      backgroundColor: Theme.of(context).colorScheme.background,
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
                      child: Text('No hay planes disponibles en este momento.'),
                    )
                  : _buildPlanList(),

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

  Widget _buildPlanList() {
    const Map<String, List<String>> planFeatures = {
      'maestro_criador_mensual': [
        'Hasta 150 gallos',
        'Módulo de Linaje',
        'Historial de Combate',
        'Bitácora de Salud',
      ],
      'maestro_criador_anual': [
        'Hasta 150 gallos',
        'Módulo de Linaje',
        'Historial de Combate',
        'Bitácora de Salud',
      ],
      'club_elite_mensual': [
        'Gallos Ilimitados',
        'Acceso Multiusuario (Próximamente)',
        'Árbol Genealógico (Próximamente)',
        'Analítica (Próximamente)',
      ],
      'club_elite_anual': [
        'Gallos Ilimitados',
        'Acceso Multiusuario (Próximamente)',
        'Árbol Genealógico (Próximamente)',
        'Analítica (Próximamente)',
      ],
    };

    List<Widget> planCards = _products.map((product) {
      bool isMaestro = product.id.startsWith('maestro_criador');
      bool isElite = product.id.startsWith('club_elite');
      String planName = isMaestro
          ? 'Maestro Criador'
          : (isElite ? 'Club de Élite' : 'Desconocido');

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: _buildPlanCard(
          context,
          title: planName,
          price: product.price,
          features: planFeatures[product.id] ?? [],
          isCurrentPlan: _currentUserPlan == (isMaestro ? 'maestro' : 'elite'),
          isRecommended: isMaestro,
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
            isCurrentPlan: _currentUserPlan == 'iniciacion',
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
        : theme.colorScheme.onBackground;
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
                    child: Text(
                      title == 'Maestro Criador'
                          ? 'Mejorar a Maestro'
                          : 'Mejorar a Élite',
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
