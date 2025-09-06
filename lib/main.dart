// Reemplaza el contenido de tu main.dart con esto:

import 'dart:io';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/login/AppInitializer.dart'; // ✅ NUEVO IMPORT
import 'package:Voltgo_User/ui/login/add_vehicle_screen.dart';
import 'package:Voltgo_User/utils/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:Voltgo_User/firebase_options.dart';
import 'package:Voltgo_User/ui/MenuPage/notifications/NotificationDetailScreen.dart';
import 'package:Voltgo_User/ui/SplashScreen.dart';
import 'package:Voltgo_User/utils/AuthWrapper.dart';
import 'package:Voltgo_User/utils/NotificationCountService.dart';
import 'package:Voltgo_User/ui/IntroPage/OnboardingWrapper.dart';
import 'package:Voltgo_User/ui/login/LoginScreen.dart';
import 'package:Voltgo_User/ui/MenuPage/DashboardScreen.dart';
import 'package:Voltgo_User/ui/MenuPage/dashboard/CombinedDashboardScreen.dart';
import 'package:Voltgo_User/ui/MenuPage/moviles/MobilesScreen.dart';
import 'package:Voltgo_User/ui/MenuPage/auditoria/AuditoriaScreen.dart';
import 'package:Voltgo_User/ui/MenuPage/notifications/NotificationsScreen.dart';
import 'package:Voltgo_User/ui/profile/SettingsScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _handleMessage(RemoteMessage message) {
  final notificationId = message.data['notificationId'];
  if (notificationId != null) {
    print('Notificación recibida, navegando a detalle ID: $notificationId');
    try {
      navigatorKey.currentState?.pushNamed(
        '/notification_detail',
        arguments: int.parse(notificationId),
      );
    } catch (e) {
      print('Error al parsear el ID de la notificación o al navegar: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      _handleMessage(message);
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Notificación recibida en primer plano: ${message.notification?.title}');
  });

  initializeDateFormatting('es_ES', null).then((_) {
    runApp(const MyApp()); // ✅ SIMPLIFICADO: Ya no necesita parámetro
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); // ✅ SIMPLIFICADO

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voltgo',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      locale: const Locale('en', ''),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
      ],
      home: const AppInitializer(), // ✅ CAMBIADO: Usa AppInitializer en lugar de AuthCheckScreen
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingWrapper());
          case '/auth_wrapper':
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const BottomNavBar());
          case '/mobiles':
            return MaterialPageRoute(builder: (_) => MobilesScreen());
          case '/auditoria':
            return MaterialPageRoute(builder: (_) => AuditoriaScreen());
          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsScreen());
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/vehicle-registration':
            return MaterialPageRoute(
              builder: (_) => AddVehicleScreen(
                onVehicleAdded: () {
                  print('🚀 onVehicleAdded ejecutado - Vehículo registrado exitosamente');
                  Navigator.of(navigatorKey.currentContext!).pop(true);
                },
              ),
            );
          case '/add-vehicle':
            return MaterialPageRoute(
              builder: (_) => AddVehicleScreen(
                onVehicleAdded: () {
                  print('🚀 onVehicleAdded ejecutado desde add-vehicle');
                  Navigator.of(navigatorKey.currentContext!).pop(true);
                },
              ),
            );
          case '/notification_detail':
            final int notificationId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => NotificationDetailScreen(notificationId: notificationId),
            );
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}