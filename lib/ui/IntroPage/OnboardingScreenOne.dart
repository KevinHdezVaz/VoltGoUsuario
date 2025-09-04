import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart'; // ✅ AGREGAR IMPORT
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreenOne extends StatelessWidget {
  const OnboardingScreenOne({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR ESTA LÍNEA

    return Stack(
      children: [
        // Fondo de la página 1 (no cambia)
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            'assets/images/rectangle1.png',
            width: MediaQuery.of(context).size.width * 0.5,
            fit: BoxFit.contain,
            color: AppColors.primary,
          ),
        ),
        Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animación
                Expanded(
                  flex: 2,
                  child: Lottie.asset(
                    'assets/images/animation11.json',
                  ),
                ),
                // Texto localizado
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        l10n.onboardingTitle1, // ✅ CAMBIAR de '¿Emergencia en el camino?'
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.onboardingSubtitle1, // ✅ CAMBIAR de 'Solicita un tecnico y sigue su trayeccto en tiempo real'
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
