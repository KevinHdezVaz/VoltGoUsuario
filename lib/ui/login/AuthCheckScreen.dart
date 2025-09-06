// auth_check_screen.dart (ejemplo)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Voltgo_User/ui/IntroPage/OnboardingWrapper.dart'; // O el widget que inicia el onboarding
import 'package:Voltgo_User/ui/login/LoginScreen.dart'; // O tu pantalla de login
import 'package:Voltgo_User/ui/SplashScreen.dart'; // Si quieres mostrar splash primero

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Espera un poco si quieres mostrar la SplashScreen antes de la verificación
    await Future.delayed(const Duration(seconds: 2)); // Ajusta la duración

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted =
        prefs.getBool('onboarding_completed') ?? false;

    if (!mounted) return; // Asegúrate de que el widget sigue montado

    if (onboardingCompleted) {
      // Si el onboarding se completó, redirige al login (o a AuthWrapper si ya tienes autenticación)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()), // O AuthWrapper()
      );
    } else {
      // Si no se completó, redirige al onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Muestra la SplashScreen mientras se verifica el estado
    return const SplashScreen();
  }
}