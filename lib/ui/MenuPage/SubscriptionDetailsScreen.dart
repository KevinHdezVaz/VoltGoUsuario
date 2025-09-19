import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Voltgo_User/data/models/UserSubscription.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';

class SubscriptionDetailsScreen extends StatelessWidget {
  final UserSubscription subscription;

  const SubscriptionDetailsScreen({
    Key? key,
    required this.subscription,
  }) : super(key: key);

  // Helper para formatear fechas
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Subscription Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.brandBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPlanSummaryCard(),
            const SizedBox(height: 24),
            _buildUsageStatisticsCard(),
            const SizedBox(height: 24),
            _buildDateInfoCard(),
            const SizedBox(height: 24),
            _buildTransactionDetailsCard(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE INFORMACIÓN ---

  // Tarjeta principal con el resumen del plan
  Widget _buildPlanSummaryCard() {
    String statusText;
    Color statusColor;

    if (subscription.isActive) {
      statusText = 'Active';
      statusColor = AppColors.success;
    } else {
      statusText = 'Inactive / Expired';
      statusColor = AppColors.textSecondary;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subscription.planName ?? 'Subscription Plan',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (subscription.planDescription != null && subscription.planDescription!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subscription.planDescription!,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              '\$${subscription.amount.toStringAsFixed(2)} ${subscription.currency}',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subscription.planType == 'monthly' ? 'Billed Monthly' : 'One-Time Payment',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta con las estadísticas de uso
  Widget _buildUsageStatisticsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardTitle(Icons.data_usage, 'Usage Statistics'),
            const SizedBox(height: 20),
            if (subscription.planType == 'one_time') ...[
              _buildDetailRow('Total Services in Plan', '${subscription.totalServices ?? 'N/A'}'),
              _buildDetailRow(
                'Services Used',
                '${(subscription.totalServices ?? 0) - (subscription.remainingServices ?? 0)}',
              ),
              _buildDetailRow('Services Remaining', '${subscription.remainingServices ?? 'N/A'}'),
            ] else ...[
              _buildDetailRow('Services Used This Period', '${subscription.servicesUsedThisMonth ?? 0}'),
              _buildDetailRow('Plan Limit', 'Unlimited'),
            ],
          ],
        ),
      ),
    );
  }

  // Tarjeta con la información de fechas
  Widget _buildDateInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardTitle(Icons.calendar_today, 'Key Dates'),
            const SizedBox(height: 20),
            _buildDetailRow('Purchase Date', _formatDate(subscription.purchasedAt)),
            if (subscription.planType == 'monthly')
              _buildDetailRow('Expires On', _formatDate(subscription.expiresAt)),
          ],
        ),
      ),
    );
  }

// En lib/ui/subscription/SubscriptionDetailsScreen.dart

// Tarjeta con los detalles de la transacción
Widget _buildTransactionDetailsCard() {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(Icons.receipt_long, 'Transaction Info'),
          const SizedBox(height: 20),

          // ✅ CORREGIDO: Muestra el ID de la suscripción de Stripe
          // que tienes en tu modelo como 'subscriptionId'.
          if (subscription.subscriptionId != null && subscription.subscriptionId!.isNotEmpty)
            _buildDetailRow('Stripe Subscription ID', subscription.subscriptionId!),
          
          // --- Para los siguientes campos, necesitas añadirlos a tu modelo ---

          // Para mostrar el 'Internal ID' (ej: #27), el campo 'id' (int)
          // debe estar en tu clase UserSubscription.
          // _buildDetailRow('Internal ID', '#${subscription.id}'),

          // Para mostrar el 'Stripe Payment ID', el campo 'stripePaymentIntentId' (String?)
          // debe estar en tu clase UserSubscription.
          // if (subscription.stripePaymentIntentId != null)
          //   _buildDetailRow('Stripe Payment ID', subscription.stripePaymentIntentId!),
        ],
      ),
    ),
  );
}

  // --- WIDGETS DE AYUDA REUTILIZABLES ---

  // Widget para el título de cada tarjeta
  Widget _buildCardTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Widget para una fila de detalle (Etiqueta y Valor)
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}