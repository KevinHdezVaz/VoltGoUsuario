import 'package:Voltgo_User/ui/login/CompleteProfileScreen.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Voltgo_User/data/services/ProfileCompletionService.dart';
import 'package:Voltgo_User/ui/login/LoginScreen.dart';
 import 'package:Voltgo_User/utils/bottom_nav.dart';
import 'package:Voltgo_User/ui/IntroPage/OnboardingWrapper.dart';
import 'package:Voltgo_User/ui/SplashScreen.dart';
import 'dart:developer' as developer;

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }



Future<void> _initializeApp() async {
  try {
    print('🚀 Iniciando verificación completa de la app...');
    
    // ✅ DEBUGGING CRÍTICO: Ver qué pasa con SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      print('📋 Todas las claves en SharedPreferences: $allKeys');
      
      final authToken = prefs.getString('auth_token');
      print('🔑 Token raw en SharedPreferences: ${authToken != null ? "✅ Existe (${authToken.substring(0, 20)}...)" : "❌ No existe"}');
    } catch (e) {
      print('❌ Error accediendo a SharedPreferences: $e');
    }

    await Future.delayed(const Duration(seconds: 2));

    // Verificar onboarding
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    print('📋 Onboarding completado: $onboardingCompleted');

    if (!onboardingCompleted) {
      print('📋 Onboarding no completado, redirigiendo...');
      setState(() {
        _initialScreen = const OnboardingWrapper();
        _isLoading = false;
      });
      return;
    }

    // ✅ DEBUGGING: Verificar token paso por paso
    print('🔍 === VERIFICANDO TOKEN ===');
    
    try {
      final hasTokenResult = await TokenStorage.hasToken();
      print('🔍 TokenStorage.hasToken() = $hasTokenResult');
    } catch (e) {
      print('❌ Error en TokenStorage.hasToken(): $e');
    }
    
    try {
      final tokenValue = await TokenStorage.getToken();
      print('🔍 TokenStorage.getToken() = ${tokenValue != null ? "token encontrado" : "null"}');
    } catch (e) {
      print('❌ Error en TokenStorage.getToken(): $e');
    }

    // Verificar con el servicio
    final profileResult = await ProfileCompletionService.checkProfileCompletion();
    print('🔍 ProfileCompletionService result: ${profileResult?.toString() ?? "null"}');

    if (profileResult == null) {
      print('❌ Error verificando perfil, ir al login');
      setState(() {
        _initialScreen = const LoginScreen();
        _isLoading = false;
      });
      return;
    }

    // Manejar resultado según el servicio
    if (profileResult.shouldGoToLogin) {
      print('🔑 Requiere autenticación, ir al login');
      setState(() {
        _initialScreen = const LoginScreen();
        _isLoading = false;
      });
      return;
    }

    if (profileResult.needsCompletion) {
      print('⚠️ Perfil incompleto, ir a CompleteProfileScreen');
      setState(() {
        _initialScreen = CompleteProfileScreen(
          user: profileResult.user!,
          token: profileResult.token!,
        );
        _isLoading = false;
      });
      return;
    }

    if (profileResult.canProceedToDashboard) {
      print('✅ Todo completo, ir al dashboard');
      setState(() {
        _initialScreen = const BottomNavBar();
        _isLoading = false;
      });
      return;
    }

    // Fallback: ir al login
    print('🤔 Estado indeterminado, ir al login por seguridad');
    setState(() {
      _initialScreen = const LoginScreen();
      _isLoading = false;
    });
    
  } catch (e, stackTrace) {
    print('❌ Error crítico en inicialización: $e');
    print('📍 StackTrace: $stackTrace');
    
    setState(() {
      _initialScreen = const LoginScreen();
      _isLoading = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    return _initialScreen ?? const LoginScreen();
  }
}