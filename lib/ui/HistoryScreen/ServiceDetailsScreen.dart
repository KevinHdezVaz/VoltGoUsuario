import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_User/data/services/ServiceDetailsModel.dart';
 import 'package:Voltgo_User/data/services/ServiceDetailsService.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceRequestModel serviceRequest;

  const ServiceDetailsScreen({
    Key? key,
    required this.serviceRequest,
  }) : super(key: key);

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  late Future<ServiceDetailsModel?> _serviceDetailsFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  void _loadServiceDetails() {
    _serviceDetailsFuture = ServiceDetailsService.fetchServiceDetails(widget.serviceRequest.id);
  }

  Future<void> _refreshDetails() async {
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      _loadServiceDetails();
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _getStatusDisplayText(String status) {
    final l10n = AppLocalizations.of(context);
    
    switch (status.toLowerCase()) {
      case 'completed':
        return l10n.completed;
      case 'cancelled':
        return l10n.cancelled;
      case 'pending':
        return l10n.pending;
      case 'accepted':
        return l10n.accepted;
      case 'en_route':
        return l10n.enRoute;
      case 'on_site':
        return l10n.onSite;
      case 'charging':
        return l10n.charging;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.serviceDetails,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
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
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: _isRefreshing 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing ? null : _refreshDetails,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDetails,
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        child: FutureBuilder<ServiceDetailsModel?>(
          future: _serviceDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildServiceInfo(),
                  const SizedBox(height: 20),
                  if (snapshot.hasData && snapshot.data != null)
                    ..._buildDetailedInfo(snapshot.data!)
                  else
                    _buildNoDetailsCard(),
                  if (widget.serviceRequest.finalCost != null) ...[
                    const SizedBox(height: 20),
                    _buildCostInfo(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingDetails ?? 'Error al cargar los detalles',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                l10n.retry,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailedInfo(ServiceDetailsModel details) {
    List<Widget> widgets = [];

    if (details.serviceStarted) {
      widgets.addAll([
        _buildServiceTimeline(details),
        const SizedBox(height: 20),
      ]);
    }

    if (details.initialBatteryLevel != null || details.chargeTimeMinutes != null) {
      widgets.addAll([
        _buildBatteryInfo(details),
        const SizedBox(height: 20),
      ]);
    }

    if (details.serviceNotes != null && details.serviceNotes!.isNotEmpty) {
      widgets.addAll([
        _buildServiceNotes(details),
        const SizedBox(height: 20),
      ]);
    }

    if (_hasPhotos(details)) {
      widgets.addAll([
        _buildPhotosSection(details),
        const SizedBox(height: 20),
      ]);
    }

    return widgets;
  }

  Widget _buildNoDetailsCard() {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noAdditionalDetails ?? 'Detalles adicionales no disponibles',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.detailsWillBeAdded ?? 'Los detalles técnicos del servicio serán agregados por el técnico durante o después del servicio.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final l10n = AppLocalizations.of(context);
    IconData icon;
    Color statusColor;
    String statusText = _getStatusDisplayText(widget.serviceRequest.status);

    switch (widget.serviceRequest.status.toLowerCase()) {
      case 'completed':
        icon = Icons.check_circle;
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        statusColor = AppColors.error;
        break;
      case 'pending':
        icon = Icons.schedule;
        statusColor = AppColors.warning;
        break;
      case 'accepted':
      case 'en_route':
      case 'on_site':
      case 'charging':
        icon = Icons.hourglass_empty;
        statusColor = AppColors.primary;
        break;
      default:
        icon = Icons.help_outline;
        statusColor = AppColors.textSecondary;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(icon, color: statusColor, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    _formatServiceDateTime(),
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
    );
  }

  String _formatServiceDateTime() {
    final dateTime = widget.serviceRequest.acceptedAt ?? 
                     widget.serviceRequest.requestedAt ?? 
                     DateTime.now();
    
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildServiceInfo() {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.serviceInformation ?? 'Información del Servicio',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.event, l10n.date ?? 'Fecha', _formatDate()),
            _buildInfoRow(Icons.access_time, l10n.time ?? 'Hora', _formatTime()),
            _buildInfoRow(Icons.info_outline, l10n.status ?? 'Estado', _getStatusDisplayText(widget.serviceRequest.status)),
            if (widget.serviceRequest.id != null)
              _buildInfoRow(Icons.confirmation_number, l10n.serviceId ?? 'ID del Servicio', '#${widget.serviceRequest.id}'),
          ],
        ),
      ),
    );
  }

  String _formatDate() {
    final dateTime = widget.serviceRequest.acceptedAt ?? 
                     widget.serviceRequest.requestedAt ?? 
                     DateTime.now();
    
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year}';
  }

  String _formatTime() {
    final dateTime = widget.serviceRequest.acceptedAt ?? 
                     widget.serviceRequest.requestedAt ?? 
                     DateTime.now();
    
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildServiceTimeline(ServiceDetailsModel details) {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.serviceTimeline ?? 'Cronología del Servicio',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (details.serviceStartTime != null)
              _buildInfoRow(Icons.play_arrow, l10n.started ?? 'Iniciado', details.formattedServiceStartTime),
            if (details.serviceCompletedAt != null)
              _buildInfoRow(Icons.check, l10n.completed, details.formattedServiceCompletedTime),
            if (details.serviceDuration != null)
              _buildInfoRow(Icons.timer, l10n.duration ?? 'Duración', details.formattedServiceDuration),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryInfo(ServiceDetailsModel details) {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.batteryInformation ?? 'Información de Batería',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (details.initialBatteryLevel != null)
              _buildInfoRow(Icons.battery_std, l10n.initialLevel ?? 'Nivel Inicial', details.batteryLevelDisplay),
            if (details.chargeTimeMinutes != null)
              _buildInfoRow(Icons.timer, l10n.chargeTime ?? 'Tiempo de Carga', details.formattedChargeTime),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceNotes(ServiceDetailsModel details) {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.serviceNotes ?? 'Notas del Servicio',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                details.serviceNotes!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPhotos(ServiceDetailsModel details) {
    return details.vehiclePhotoUrl != null || 
           details.beforePhotoUrl != null || 
           details.afterPhotoUrl != null;
  }

  Widget _buildPhotosSection(ServiceDetailsModel details) {
    final l10n = AppLocalizations.of(context);
    List<Widget> photoWidgets = [];
    
    if (details.vehiclePhotoUrl != null) {
      photoWidgets.add(Expanded(child: _buildPhotoCard(l10n.vehicle ?? 'Vehículo', details.vehiclePhotoUrl!)));
    }
    
    if (details.beforePhotoUrl != null) {
      if (photoWidgets.isNotEmpty) photoWidgets.add(const SizedBox(width: 8));
      photoWidgets.add(Expanded(child: _buildPhotoCard(l10n.before ?? 'Antes', details.beforePhotoUrl!)));
    }
    
    if (details.afterPhotoUrl != null) {
      if (photoWidgets.isNotEmpty) photoWidgets.add(const SizedBox(width: 8));
      photoWidgets.add(Expanded(child: _buildPhotoCard(l10n.after ?? 'Después', details.afterPhotoUrl!)));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.servicePhotos ?? 'Fotos del Servicio',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(children: photoWidgets),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String title, String photoUrl) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showPhotoDialog(photoUrl, title),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.lightGrey,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.lightGrey,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoDialog(String photoUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Error al cargar la imagen',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Cargando $title...',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostInfo() {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentInformation ?? 'Información de Pago',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.totalCost ?? 'Costo Total:',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\${widget.serviceRequest.finalCost!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}