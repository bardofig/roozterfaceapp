// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart'; // Importamos Provider
import 'package:roozterfaceapp/screens/splash_screen.dart';
import 'package:roozterfaceapp/services/payment_service.dart';
import 'package:roozterfaceapp/theme/theme_provider.dart'; // Importamos nuestro proveedor
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  PaymentService().initialize();

  // Envolvemos nuestra app con el ChangeNotifierProvider
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoozterFace',
      // El tema ahora se obtiene dinámicamente del proveedor
      theme: Provider.of<ThemeProvider>(context).themeData,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', '')],
      home: const SplashScreen(),
    );
  }
}
