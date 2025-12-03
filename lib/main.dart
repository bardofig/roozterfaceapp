// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/providers/rooster_list_provider.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/splash_screen.dart';
import 'package:roozterfaceapp/services/payment_service.dart';
import 'package:roozterfaceapp/theme/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  PaymentService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => RoosterListProvider()),
      ],
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
      theme: Provider.of<ThemeProvider>(context).themeData,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
      locale: const Locale('es'),
      // La pantalla de inicio de la aplicación ahora es SplashScreen.
      home: const SplashScreen(),
    );
  }
}
