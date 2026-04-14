// lib/utils/subscription_utils.dart

import 'package:roozterfaceapp/models/user_model.dart';

enum AppFeature {
  advancedStatistics,
  memberManagement,
  exportPdf,
  unlimitedRoosters,
}

class SubscriptionUtils {
  /// Retorna si el plan del usuario permite acceder a una funcionalidad específica.
  /// Actualmente permite todo para facilitar las pruebas, pero está estructurado
  /// para ser bloqueado fácilmente en el futuro.
  static bool canAccessFeature(UserModel? user, AppFeature feature) {
    if (user == null) return false;

    // TODO: En producción, habilitar estas validaciones según el plan.
    // final plan = user.plan.toLowerCase();
    
    // Por ahora permitimos todo (Pruebas Beta)
    return true; 

    /* Ejemplo de lógica futura:
    switch (feature) {
      case AppFeature.advancedStatistics:
        return plan == 'professional' || plan == 'business';
      case AppFeature.memberManagement:
        return plan == 'business';
      case AppFeature.unlimitedRoosters:
        return plan != 'free';
      default:
        return true;
    }
    */
  }
}
