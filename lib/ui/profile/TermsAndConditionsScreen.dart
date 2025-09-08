import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:flutter/material.dart'; 

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.termsAndConditions ?? 'Términos y Condiciones',
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
                        Icons.gavel,
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
                            l10n.termsAndConditions ?? 'Términos y Condiciones',
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
              title: l10n.acceptance ?? '1. Aceptación de los Términos',
              content: l10n.acceptanceContent ?? 'Aquí irá el texto de términos y condiciones sobre la aceptación de los términos de uso de la aplicación VoltGo.',
              icon: Icons.check_circle_outline,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.serviceDescription ?? '2. Descripción del Servicio',
              content: l10n.serviceDescriptionContent ?? 'Aquí irá el texto que describe los servicios ofrecidos por VoltGo, incluyendo carga de vehículos eléctricos y asistencia técnica.',
              icon: Icons.electric_car,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.userResponsibilities ?? '3. Responsabilidades del Usuario',
              content: l10n.userResponsibilitiesContent ?? 'Aquí irá el texto sobre las responsabilidades y obligaciones del usuario al utilizar la plataforma VoltGo.',
              icon: Icons.person_outline,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.technicianObligations ?? '4. Obligaciones de los Técnicos',
              content: l10n.technicianObligationsContent ?? 'Aquí irá el texto sobre las obligaciones y responsabilidades de los técnicos registrados en la plataforma.',
              icon: Icons.engineering,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.paymentTerms ?? '5. Términos de Pago',
              content: l10n.paymentTermsContent ?? 'Aquí irá el texto sobre los términos de pago, facturación y políticas de reembolso.',
              icon: Icons.payment,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.limitation ?? '6. Limitación de Responsabilidad',
              content: l10n.limitationContent ?? 'Aquí irá el texto sobre las limitaciones de responsabilidad de VoltGo ante daños o inconvenientes.',
              icon: Icons.shield_outlined,
            ),
            
            const SizedBox(height: 16),
            
            _buildSection(
              title: l10n.modifications ?? '7. Modificaciones',
              content: l10n.modificationsContent ?? 'Aquí irá el texto sobre cómo y cuándo VoltGo puede modificar estos términos y condiciones.',
              icon: Icons.edit_outlined,
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
                      l10n.questionsContact ?? 'Si tienes preguntas sobre estos términos, contáctanos en:',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'legal@voltgo.com',
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