import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:flutter/material.dart'; 

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.privacyPolicy ?? 'Política de Privacidad',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.brandBlue.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: AppColors.gray300.withOpacity(0.4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.privacy_tip,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.privacyPolicy ?? 'Política de Privacidad',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.lastUpdated ?? 'Última actualización: Enero 2025',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Content Sections
            _buildSection(
              title: l10n.dataCollection ?? '1. Información que Recopilamos',
              content: l10n.dataCollectionContent ?? 'Aquí irá el texto sobre qué datos personales recopila VoltGo, incluyendo información de perfil, ubicación y uso de la aplicación.',
              icon: Icons.data_usage,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.dataUsage ?? '2. Cómo Usamos tu Información',
              content: l10n.dataUsageContent ?? 'Aquí irá el texto sobre cómo VoltGo utiliza los datos recopilados para proporcionar servicios, mejorar la experiencia y comunicarse con los usuarios.',
              icon: Icons.settings_applications,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.locationData ?? '3. Datos de Ubicación',
              content: l10n.locationDataContent ?? 'Aquí irá el texto sobre cómo VoltGo recopila y utiliza datos de ubicación para conectar usuarios con técnicos cercanos.',
              icon: Icons.location_on,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.dataSharing ?? '4. Compartir Información',
              content: l10n.dataSharingContent ?? 'Aquí irá el texto sobre cuándo y con quién VoltGo puede compartir información personal de los usuarios.',
              icon: Icons.share,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.dataSecurity ?? '5. Seguridad de Datos',
              content: l10n.dataSecurityContent ?? 'Aquí irá el texto sobre las medidas de seguridad implementadas para proteger la información personal de los usuarios.',
              icon: Icons.security,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.userRights ?? '6. Derechos del Usuario',
              content: l10n.userRightsContent ?? 'Aquí irá el texto sobre los derechos de los usuarios respecto a sus datos personales, incluyendo acceso, corrección y eliminación.',
              icon: Icons.account_circle,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.cookies ?? '7. Cookies y Tecnologías Similares',
              content: l10n.cookiesContent ?? 'Aquí irá el texto sobre el uso de cookies y otras tecnologías de seguimiento en la aplicación VoltGo.',
              icon: Icons.cookie,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.thirdPartyServices ?? '8. Servicios de Terceros',
              content: l10n.thirdPartyServicesContent ?? 'Aquí irá el texto sobre los servicios de terceros integrados en VoltGo y sus políticas de privacidad.',
              icon: Icons.extension,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.dataRetention ?? '9. Retención de Datos',
              content: l10n.dataRetentionContent ?? 'Aquí irá el texto sobre cuánto tiempo VoltGo conserva los datos personales de los usuarios.',
              icon: Icons.schedule,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.minorPrivacy ?? '10. Privacidad de Menores',
              content: l10n.minorPrivacyContent ?? 'Aquí irá el texto sobre las políticas especiales de privacidad para usuarios menores de edad.',
              icon: Icons.child_care,
            ),
            
            const SizedBox(height: 32),
            
            // Contact Information
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.contact_support, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.contactUs ?? 'Contacto',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.privacyQuestions ?? 'Para preguntas sobre privacidad, contáctanos en:',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'privacy@voltgo.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
            color: Colors.blue.shade50,

      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}