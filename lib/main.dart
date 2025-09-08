import 'dart:io';
 import 'package:Voltgo_User/data/services/ServiceChatScreen.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/login/AppInitializer.dart';
import 'package:Voltgo_User/ui/login/add_vehicle_screen.dart';
import 'package:Voltgo_User/utils/ChatNotificationProvider.dart';
import 'package:Voltgo_User/utils/OneSignalService.dart';
import 'package:Voltgo_User/utils/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:Voltgo_User/firebase_options.dart';
 import 'package:Voltgo_User/ui/SplashScreen.dart';
import 'package:Voltgo_User/utils/AuthWrapper.dart';
 import 'package:Voltgo_User/ui/IntroPage/OnboardingWrapper.dart';
import 'package:Voltgo_User/ui/login/LoginScreen.dart';
import 'package:Voltgo_User/ui/MenuPage/DashboardScreen.dart';
import 'package:Voltgo_User/ui/MenuPage/dashboard/CombinedDashboardScreen.dart';
import 'package:Voltgo_User/ui/MenuPage/moviles/MobilesScreen.dart';
import 'package:Voltgo_User/ui/MenuPage/auditoria/AuditoriaScreen.dart';
 import 'package:Voltgo_User/ui/profile/SettingsScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'data/services/NotificationsService.dart'; // ✅ NUEVO
 
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Manejar notificaciones Firebase (existente)
void _handleMessage(RemoteMessage message) {
  final notificationId = message.data['notificationId'];
  
  if (notificationId != null) {
    print('Notificación Firebase recibida, navegando a detalle ID: $notificationId');
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
  
  try {
    // Cargar variables de entorno
    await dotenv.load(fileName: ".env");
    print('Variables de entorno cargadas');

    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado');

    // ✅ NUEVO: Inicializar OneSignal
    await OneSignalService.initialize();
    print('OneSignal inicializado');

    // ✅ NUEVO: Inicializar NotificationService para sonidos locales
    NotificationService.reinitialize();
    print('NotificationService inicializado');

    // Configurar Firebase Messaging (existente)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessage(message);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación Firebase en primer plano: ${message.notification?.title}');
    });

    print('Todos los servicios inicializados correctamente');

  } catch (e, stackTrace) {
    print('Error inicializando servicios: $e');
    print('StackTrace: $stackTrace');
    // Continuar para no bloquear la app completamente
  }

  // ✅ NUEVO: Verificar onboarding
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  initializeDateFormatting('es_ES', null).then((_) {
    runApp(MyApp(onboardingCompleted: onboardingCompleted)); // ✅ ACTUALIZADO
  });
}

class MyApp extends StatefulWidget { // ✅ CAMBIADO A StatefulWidget
  final bool onboardingCompleted; // ✅ NUEVO

  const MyApp({Key? key, required this.onboardingCompleted}) : super(key: key); // ✅ ACTUALIZADO

  @override
  State<MyApp> createState() => _MyAppState(); // ✅ NUEVO
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver { // ✅ NUEVA CLASE
  
  @override
  void initState() {
    super.initState();
    
    // ✅ NUEVO: Observar ciclo de vida de la app
    WidgetsBinding.instance.addObserver(this);
    print('MyApp inicializada - observando ciclo de vida');
  }

  @override
  void dispose() {
    // ✅ NUEVO: Limpiar observer y servicios
    WidgetsBinding.instance.removeObserver(this);
    
    // Limpiar servicios
    OneSignalService.dispose();
    NotificationService.dispose();
    
    super.dispose();
  }

  /// ✅ NUEVO: Manejar cambios en el ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('Cambio en ciclo de vida: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('App en primer plano');
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        print('App pausada (segundo plano)');
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        print('App inactiva');
        break;
      case AppLifecycleState.detached:
        print('App desconectada');
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  /// ✅ NUEVO: Manejar cuando la app pasa a primer plano
  void _handleAppResumed() {
    try {
      OneSignalService.updateAppState('foreground');
      NotificationService.reinitialize();
    } catch (e) {
      print('Error manejando app resumed: $e');
    }
  }

  /// ✅ NUEVO: Manejar cuando la app pasa a segundo plano
  void _handleAppPaused() {
    try {
      OneSignalService.updateAppState('background');
      NotificationService.stop().catchError((e) {
        print('Error deteniendo sonido al pausar app: $e');
      });
    } catch (e) {
      print('Error manejando app paused: $e');
    }
  }

  /// ✅ NUEVO: Manejar cuando la app se desconecta
  void _handleAppDetached() {
    try {
      OneSignalService.updateAppState('background');
    } catch (e) {
      print('Error manejando app detached: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // ✅ NUEVO: Envolver en MultiProvider
      providers: [
        // ✅ NUEVO: Agregar Chat Notification Provider
        ChangeNotifierProvider(
          create: (context) => ChatNotificationProvider(),
        ),
        // Aquí puedes agregar otros providers que tengas
      ],
      child: MaterialApp(
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
        home: const AppInitializer(), // ✅ MANTIENE AppInitializer
        onGenerateRoute: (settings) {
          print('Navegando a ruta: ${settings.name}'); // ✅ NUEVO: Log de navegación
          
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
             
            // ✅ NUEVA RUTA PARA CHAT
            case '/chat':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args['serviceRequest'] != null) {
                return MaterialPageRoute(
                  builder: (_) => ServiceChatScreen(
                    serviceRequest: args['serviceRequest'],
                    userType: args['userType'] ?? 'user', // El usuario siempre será 'user'
                  ),
                );
              }
              return MaterialPageRoute(builder: (_) => const SplashScreen());

            default:
              print('Ruta no encontrada: ${settings.name}'); // ✅ NUEVO: Log de error
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
        
        // ✅ NUEVO: Builder para configurar UI global y OneSignal context
        builder: (context, child) {
          // Configurar contexto para OneSignal
          WidgetsBinding.instance.addPostFrameCallback((_) {
            OneSignalService.setContext(context);
          });
          
          return child ?? Container();
        },
      ),
    );
  }
}