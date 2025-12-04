import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // 1. Solicitar permisos
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('Permiso de notificaciones concedido');
      }
      
      // 2. Obtener y guardar token
      await _saveTokenToDatabase();

      // 3. Configurar listeners
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Mensaje recibido en primer plano: ${message.notification?.title}');
        }
        // Aquí podrías mostrar un snackbar o diálogo local si lo deseas
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Mensaje abierto desde segundo plano: ${message.data}');
        }
        // Aquí podrías navegar a una pantalla específica
      });
    } else {
      if (kDebugMode) {
        print('Permiso de notificaciones denegado');
      }
    }
  }

  Future<void> _saveTokenToDatabase() async {
    String? token = await _messaging.getToken();
    User? user = _auth.currentUser;

    if (user != null && token != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }).catchError((e) {
        if (kDebugMode) {
          print('Error al guardar token FCM: $e');
        }
      });
    }
    
    // Escuchar cambios en el token
    _messaging.onTokenRefresh.listen((newToken) async {
       User? currentUser = _auth.currentUser;
       if (currentUser != null) {
         await _firestore.collection('users').doc(currentUser.uid).update({
           'fcmToken': newToken,
           'lastTokenUpdate': FieldValue.serverTimestamp(),
         });
       }
    });
  }
}
