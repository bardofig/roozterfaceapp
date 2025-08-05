import 'package:flutter/material.dart';

// Por ahora, solo es un contenedor temporal.
// Más adelante, aquí irá la lógica de Firebase Auth.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Este será el lugar donde decidiremos a qué pantalla ir.
        // Por ahora, nos sirve para confirmar que todo funciona.
        child: Text(
          "Punto de Control de Autenticación",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
