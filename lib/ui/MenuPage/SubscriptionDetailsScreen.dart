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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper para calcular próxima fecha de reset (solo para planes mensuales)
  String _getNextResetDate() {
    if (subscription.planType != 'monthly' || subscription.purchasedAt == null) {
      return 'N/A';
    }

    final purchaseDate = subscription.purchasedAt!;
    final now = DateTime.now();
    
    // Calcular cuántos meses han pasado
    int monthsPassed = ((now.year - purchaseDate.year) * 12) + (now.month - purchaseDate.month);
    
    // Si aún no ha pasado el día de compra este mes, usar el mes actual
    if (now.day < purchaseDate.day) {
      monthsPassed--;
    }
    
    // Próxima fecha de reset
    DateTime nextReset = DateTime(
      purchaseDate.year,
      purchaseDate.month + monthsPassed + 1,
      purchaseDate.day,
    );
    
    return _formatDate(nextReset);
  }

  // Helper para calcular días hasta el próximo reset
  int _getDaysUntilReset() {
    if (subscription.planType != 'monthly' || subscription.purchasedAt == null) {
      return 0;
    }

    final purchaseDate = subscription.purchasedAt!;
    final now = DateTime.now();
    
    int monthsPassed = ((now.year - purchaseDate.year) * 12) + (now.month - purchaseDate.month);
    if (now.day < purchaseDate.day) {
      monthsPassed--;
    }
    
    DateTime nextReset = DateTime(
      purchaseDate.year,
      purchaseDate.month + monthsPassed + 1,
      purchaseDate.day,
    );
    
    return nextReset.difference(now).inDays + 1;
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
      color: Colors.white,
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

Widget _buildUsageStatisticsCard() {
  return Card(
    elevation: 4,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(Icons.data_usage, 'Service Usage'),
          const SizedBox(height: 20),
          
          if (subscription.planType == 'one_time') ...[
            // Para planes únicos
            _buildDetailRow('Plan Type', 'One-Time Service'),
            _buildDetailRow('Service Type', _getServiceType()),
            
            if (subscription.remainingServices != null) ...[
              _buildDetailRow('Services Available', '${subscription.remainingServices}'),
              
              // Solo mostrar progreso si se han usado servicios
              if (subscription.remainingServices == 0) ...[
                const SizedBox(height: 16),
                _buildWarningBanner(
                  Icons.check_circle,
                  'Service has been completed.',
                  Colors.green,
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ready to use when needed.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              _buildDetailRow('Services Available', 'N/A'),
            ],
            
          ] else if (subscription.planType == 'monthly') ...[
            // Para planes mensuales
            _buildDetailRow('Plan Type', 'Monthly Subscription'),
            _buildDetailRow('Service Type', _getServiceType()),
            
            if (subscription.remainingServices != null) ...[
              // Plan mensual con límite de servicios
              ..._buildMonthlyServicesInfo(),
              
            ] else ...[
              // Plan mensual ilimitado
              _buildDetailRow('Monthly Limit', 'Unlimited'),
              _buildDetailRow('Next Billing', _formatDate(subscription.expiresAt)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unlimited services this month',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          
          // Mostrar advertencias si es necesario
          if (subscription.isActive) ...[
            const SizedBox(height: 16),
            _buildUsageWarnings(),
          ],
        ],
      ),
    ),
  );
}

// Método separado para manejar la información de servicios mensuales
List<Widget> _buildMonthlyServicesInfo() {
  int totalMonthlyServices = _getTotalMonthlyServices();
  int usedThisMonth = totalMonthlyServices - subscription.remainingServices!;
  
  return [
    _buildDetailRow('Services This Month', '${subscription.remainingServices} of $totalMonthlyServices'),
    _buildDetailRow('Used This Month', '$usedThisMonth'),
    _buildDetailRow('Next Reset', _getNextResetDate()),
    _buildDetailRow('Days Until Reset', '${_getDaysUntilReset()} days'),
    
    // Mostrar barra de progreso para planes mensuales
    const SizedBox(height: 16),
    _buildMonthlyUsageProgressBar(usedThisMonth, totalMonthlyServices),
  ];
}

String _getServiceType() {
  final planName = subscription.planName?.toLowerCase() ?? '';
  
  if (planName.contains('tire') || planName.contains('flat')) {
    return 'Tire Repair Service';
  } else if (planName.contains('battery')) {
    return 'Battery Replacement Service';
  } else if (planName.contains('ev on-demand') || planName.contains('schedule')) {
    return 'EV Charging Service';
  } else if (planName.contains('fleet')) {
    return 'Fleet Roadside Services';
  } else if (planName.contains('plus')) {
    return 'Enhanced Roadside Services';
  }
  
  return 'Roadside Service';
}

int _getTotalMonthlyServices() {
  final planName = subscription.planName?.toLowerCase() ?? '';
  
  // Mapeo específico por nombre de plan
  if (planName.contains('safe roads fleet') || planName.contains('fleet')) {
    return 10;
  } else if (planName.contains('safe roads plus') || planName.contains('plus')) {
    return 2;
  }
  
  // Por defecto para planes mensuales
  return 2;
}


// Método para mostrar la barra de progreso específica para planes mensuales
Widget _buildMonthlyUsageProgressBar(int used, int total) {
  double progress = total > 0 ? used / total : 0;
  
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Monthly Usage',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
          Text(
            '$used of $total used',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(
          progress > 0.8 ? Colors.red : 
          progress > 0.5 ? Colors.orange : 
          AppColors.primary,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        progress >= 1.0 ? 'All services used this month' :
        progress > 0.8 ? 'Low services remaining' :
        progress > 0.5 ? 'Moderate usage' : 'Good availability',
        style: GoogleFonts.inter(
          fontSize: 12, 
          color: progress > 0.8 ? Colors.red : AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
  );
}


  // ✅ NUEVO: Barra de progreso de uso
Widget _buildUsageProgressBar() {
  if (subscription.remainingServices == null) return Container();
  
  int totalServices;
  int used;
  
  if (subscription.planType == 'one_time') {
    // Para planes únicos, mostrar servicios restantes vs total original
    // Obtener servicios originales del nombre del plan
    if (subscription.planName?.toLowerCase().contains('flota') == true) {
      totalServices = 10;
    } else if (subscription.planName?.toLowerCase().contains('plus') == true) {
      totalServices = 2;
    } else {
      totalServices = 1; // La mayoría de planes únicos son 1 servicio
    }
    
    used = totalServices - subscription.remainingServices!;
  } else {
    // Para planes mensuales
    if (subscription.planName?.toLowerCase().contains('plus') == true) {
      totalServices = 2;
    } else if (subscription.planName?.toLowerCase().contains('flota') == true) {
      totalServices = 10;
    } else if (subscription.planName?.toLowerCase().contains('premium') == true) {
      totalServices = 5;
    } else {
      totalServices = 2; // Por defecto para mensuales
    }
    
    used = totalServices - subscription.remainingServices!;
  }
  
  double progress = totalServices > 0 ? used / totalServices : 0;
  
  return Column(
    children: [
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Usage Progress',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
          Text(
            '$used of $totalServices used',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(
          progress > 0.8 ? Colors.red : AppColors.primary,
        ),
      ),
    ],
  );
}


  // ✅ NUEVO: Advertencias de uso
  Widget _buildUsageWarnings() {
    List<Widget> warnings = [];
    
    if (subscription.remainingServices != null) {
      if (subscription.remainingServices == 0) {
        if (subscription.planType == 'monthly') {
          warnings.add(_buildWarningBanner(
            Icons.info_outline,
            'Services exhausted for this month. They will reset on ${_getNextResetDate()}.',
            Colors.orange,
          ));
        } else {
          warnings.add(_buildWarningBanner(
            Icons.warning_outlined,
            'All services have been used. Purchase a new plan to continue.',
            Colors.red,
          ));
        }
      } else if (subscription.remainingServices == 1) {
        warnings.add(_buildWarningBanner(
          Icons.info_outline,
          'Only 1 service remaining${subscription.planType == 'monthly' ? ' this month' : ''}.',
          Colors.orange,
        ));
      }
    }
    
    // Advertencia de expiración
    if (subscription.planType == 'monthly' && subscription.expiresAt != null) {
      final daysUntilExpiry = subscription.expiresAt!.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 3 && daysUntilExpiry >= 0) {
        warnings.add(_buildWarningBanner(
          Icons.schedule_outlined,
          'Subscription expires in $daysUntilExpiry days.',
          Colors.orange,
        ));
      }
    }
    
    return Column(children: warnings);
  }

  // ✅ NUEVO: Banner de advertencia
  Widget _buildWarningBanner(IconData icon, String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ACTUALIZADA: Tarjeta con la información de fechas
  Widget _buildDateInfoCard() {
    return Card(
      color: Colors.white,
     elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardTitle(Icons.calendar_today, 'Important Dates'),
            const SizedBox(height: 20),
            _buildDetailRow('Purchase Date', _formatDate(subscription.purchasedAt)),
            
            if (subscription.planType == 'monthly') ...[
              if (subscription.expiresAt != null)
                _buildDetailRow('Expires On', _formatDate(subscription.expiresAt)),
              
              if (subscription.remainingServices != null)
                _buildDetailRow('Services Reset On', _getNextResetDate()),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ ACTUALIZADA: Tarjeta con los detalles de la transacción
  Widget _buildTransactionDetailsCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardTitle(Icons.receipt_long, 'Transaction Details'),
            const SizedBox(height: 20),

            // ✅ ID interno de la suscripción (si tienes el campo 'id')
            // _buildDetailRow('Internal ID', '#${subscription.id}'),

            // ✅ ID de suscripción de Stripe (para planes mensuales)
            if (subscription.subscriptionId != null && subscription.subscriptionId!.isNotEmpty)
              _buildDetailRow('Stripe Subscription ID', subscription.subscriptionId!),
            
            // ✅ ID de Payment Intent de Stripe (para planes únicos)
            // if (subscription.stripePaymentIntentId != null && subscription.stripePaymentIntentId!.isNotEmpty)
            //   _buildDetailRow('Stripe Payment ID', subscription.stripePaymentIntentId!),

            _buildDetailRow('Plan Type', subscription.planType == 'monthly' ? 'Recurring' : 'One-Time'),
            _buildDetailRow('Currency', subscription.currency.toUpperCase()),
            _buildDetailRow('Amount Paid', '\$${subscription.amount.toStringAsFixed(2)}'),
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