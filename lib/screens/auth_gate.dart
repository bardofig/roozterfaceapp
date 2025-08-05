import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Punto de Control de Autenticación",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
