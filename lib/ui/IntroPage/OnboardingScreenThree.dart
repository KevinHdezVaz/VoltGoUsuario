import 'package:flutter/material.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart'; // ✅ AGREGAR IMPORT
import 'package:lottie/lottie.dart';

class OnboardingscreenThree extends StatelessWidget {
  const OnboardingscreenThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: _buildContent(context),
        ),
        _buildBackground(context),
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    // Este widget no cambia
    return Stack(
      children: [
        Positioned(
          left: 0,
          bottom: 0,
          child: Image.asset(
            'assets/images/rectangle3.png',
            width: MediaQuery.of(context).size.width * 0.5,
            fit: BoxFit.contain,
            color: AppColors.primary,
          ),
        ),
        Positioned(
          top: -90,
          right: 0,
          child: Image.asset(
            'assets/images/rectangle1.png',
            width: MediaQuery.of(context).size.width * 0.5,
            fit: BoxFit.contain,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR ESTA LÍNEA

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Lottie.asset(
              'assets/images/animation3.json',
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  l10n.onboardingTitle3, // ✅ CAMBIAR de 'Notificaciones'
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.onboardingSubtitle3, // ✅ CAMBIAR de 'Infórmate sobre promociones, eventos y noticias relevantes de la app.'
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
