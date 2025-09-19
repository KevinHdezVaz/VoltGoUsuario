import 'package:Voltgo_User/ui/MenuPage/SubscriptionDetailsScreen.dart';
import 'package:flutter/material.dart';

 import 'package:google_fonts/google_fonts.dart';
import 'package:Voltgo_User/data/models/UserSubscription.dart';
import 'package:Voltgo_User/data/services/SubscriptionService.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
// Importa la futura pantalla de detalles (la crearemos en el siguiente paso)
// import 'SubscriptionDetailsScreen.dart'; 

class SubscriptionHistoryScreen extends StatefulWidget {
  const SubscriptionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionHistoryScreen> createState() => _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState extends State<SubscriptionHistoryScreen> {
  late Future<List<UserSubscription>> _historyFuture;

  @override
  void initState() {
    super.initState();
    // Iniciamos la carga de datos en cuanto la pantalla se crea
    _historyFuture = SubscriptionService.getSubscriptionHistory();
  }

  // Función para reintentar la carga de datos
  void _reloadData() {
    setState(() {
      _historyFuture = SubscriptionService.getSubscriptionHistory();
    });
  }

  // Helper para formatear la fecha
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Purchase History',
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
      body: FutureBuilder<List<UserSubscription>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          // --- ESTADO DE CARGA ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // --- ESTADO DE ERROR ---
          if (snapshot.hasError) {
            return _buildErrorState('Error loading history: ${snapshot.error}');
          }

          // --- ESTADO CON DATOS ---
          if (snapshot.hasData) {
            final history = snapshot.data!;

            if (history.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final subscription = history[index];
                return _buildHistoryItemCard(subscription);
              },
            );
          }

          // --- ESTADO POR DEFECTO (NO DEBERÍA OCURRIR) ---
          return _buildEmptyState();
        },
      ),
    );
  }

   Widget _buildHistoryItemCard(UserSubscription sub) {
    // Lógica para determinar el texto y color del estado
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (sub.isActive) {
      statusText = 'Active';
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (sub.planType == 'one_time' && (sub.remainingServices ?? 0) <= 0) {
      statusText = 'Completed';
      statusColor = AppColors.brandBlue;
      statusIcon = Icons.task_alt;
    } else {
      statusText = 'Expired / Inactive';
      statusColor = AppColors.textSecondary;
      statusIcon = Icons.cancel;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // ✅ THIS IS THE CORRECTED PART ✅
        onTap: () {
          // This code will now execute when you tap the card.
          // It creates the details screen and passes the specific
          // subscription ('sub') that was tapped.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubscriptionDetailsScreen(subscription: sub),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icono principal del plan
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(
                  sub.planType == 'monthly' ? Icons.autorenew : Icons.confirmation_number,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Detalles del plan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.planName ?? 'Subscription',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // We use the 'createdAt' field from your model
                      'Purchased: ${_formatDate(sub.createdAt)}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    // Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Flecha para indicar que es clickeable
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
  // --- WIDGETS DE ESTADO (VACÍO Y ERROR) ---

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              'No Subscription History',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your past and current subscriptions will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              'Something Went Wrong',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reloadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            )
          ],
        ),
      ),
    );
  }
}