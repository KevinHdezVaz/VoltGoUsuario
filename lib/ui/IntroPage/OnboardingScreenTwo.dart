import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart'; // ✅ AGREGAR IMPORT
import 'package:lottie/lottie.dart';

class OnboardingscreenTwo extends StatelessWidget {
  const OnboardingscreenTwo({Key? key}) : super(key: key);

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
    // Este widget no necesita cambios
    return Stack(
      children: [
        Positioned(
          bottom: -50,
          right: 0,
          child: Transform.rotate(
            angle: 0.0,
            child: Image.asset(
              'assets/images/rectangle2_2.png',
              width: MediaQuery.of(context).size.width * 0.4,
              fit: BoxFit.contain,
              color: AppColors.primary,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: -50,
          child: Image.asset(
            'assets/images/rectangle2.png',
            width: MediaQuery.of(context).size.width * 0.6,
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
              'assets/images/animation22.json',
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  l10n.onboardingTitle2, // ✅ CAMBIAR de 'Profesionales capacitados y verificados.'
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.onboardingSubtitle2, // ✅ CAMBIAR de 'Contamos con personal capacitado para tu tipo de vehiculo y con certificaciones.'
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
