import 'dart:async';
import 'dart:math' as math;
import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_User/data/services/ServiceChatScreen.dart';
import 'package:Voltgo_User/data/services/ServiceRequestService.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/utils/ChatNotificationProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
 
class RealTimeTrackingScreen extends StatefulWidget {
  final ServiceRequestModel serviceRequest;
  final VoidCallback? onServiceComplete;
  final VoidCallback? onCancel;
  final bool canStillCancel;

  const RealTimeTrackingScreen({
    Key? key,
    required this.serviceRequest,
    this.onServiceComplete,
    this.onCancel,
    this.canStillCancel = true,
  }) : super(key: key);

  @override
  State<RealTimeTrackingScreen> createState() => _RealTimeTrackingScreenState();
}

class _RealTimeTrackingScreenState extends State<RealTimeTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;  Timer? _trackingTimer;
  Timer? _statusTimer;
  ServiceRequestModel? _activeServiceRequest;

  // Locations
  LatLng? _technicianLocation;
  late LatLng _clientLocation;

  // Markers
  Set<Marker> _markers = {};

  // Service information
  late ServiceRequestModel _currentRequest;
  double _distanceToClient = 0.0;
  int _estimatedArrivalMinutes = 0;
  String _technicianName = '';
  String _technicianPhone = '';
  String _vehicleInfo = '';
  String _technicianRating = '5.0';

  // UI State
  bool _isLoading = false;
  bool _showDetails = true;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.serviceRequest;
    _activeServiceRequest = widget.serviceRequest;
    _initializeData();
    _initializeAnimations();
    _startTracking();
    _startStatusMonitoring();
  }

  void _initializeData() {
    _clientLocation = LatLng(
      _currentRequest.requestLat,
      _currentRequest.requestLng,
    );

    final technician = _currentRequest.technician;
    _technicianName = technician?.name ?? AppLocalizations.of(context).technicianName;
    _technicianRating =
        double.tryParse(technician?.profile?.averageRating ?? '5.0')
                ?.toStringAsFixed(1) ??
            '5.0';
    _vehicleInfo =
        technician?.profile?.vehicleDescription ?? AppLocalizations.of(context).serviceVehicle;
  }

  String _buildVehicleInfoFromTechnician(dynamic technician) {
    final profile = technician?.profile;
    if (profile?.vehicleDetails == null || profile.vehicleDetails.isEmpty) {
      return AppLocalizations.of(context).serviceVehicle;
    }

    final make = profile.vehicleMake ?? '';
    final model = profile.vehicleModel ?? '';
    final plate = profile.vehiclePlate ?? '';

    final parts = <String>[];
    if (make.isNotEmpty) parts.add(make);
    if (model.isNotEmpty) parts.add(model);
    if (plate.isNotEmpty) parts.add('($plate)');

    return parts.isNotEmpty ? parts.join(' ') : AppLocalizations.of(context).serviceVehicle;
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _startTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _updateTechnicianLocation();
    });
    _updateTechnicianLocation();
  }

  void _startStatusMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkServiceStatus();
    });
  }

  Future<void> _updateTechnicianLocation() async {
    try {
      final technicianLocation =
          await ServiceRequestService.getTechnicianLocation(
        _currentRequest.id,
      );

      if (technicianLocation != null && mounted) {
        setState(() {
          _technicianLocation = technicianLocation;
          _calculateDistanceAndTime();
          _updateMarkers();
        });

        _fitMapToShowBothLocations();
      }
    } catch (e) {
      print('Error updating technician location: $e');
    }
  }

  Future<void> _checkServiceStatus() async {
    try {
      final updatedRequest =
          await ServiceRequestService.getRequestStatus(_currentRequest.id);

      if (mounted && updatedRequest.status != _currentRequest.status) {
        setState(() {
          _currentRequest = updatedRequest;
        });

        _handleStatusChange(updatedRequest.status);
      }
    } catch (e) {
      print('Error checking service status: $e');
    }
  }

  void _handleStatusChange(String newStatus) {
    final l10n = AppLocalizations.of(context);
    switch (newStatus) {
      case 'on_site':
        _showStatusAlert(
          l10n.technicianArrived,
          l10n.technicianArrivedMessage,
          Colors.green,
        );
        break;
      case 'charging':
        _showStatusAlert(
          l10n.serviceStarted,
          l10n.serviceStartedMessage,
          AppColors.primary,
        );
        break;
      case 'completed':
        _showStatusAlert(
          l10n.serviceCompleted,
          l10n.serviceCompletedMessage,
          Colors.green,
        );
        widget.onServiceComplete?.call();
        _navigateBackWithResult();
        break;
      case 'cancelled':
        _showStatusAlert(
          l10n.serviceCancelled,
          l10n.serviceCancelledMessage,
          Colors.red,
        );
        _navigateBackWithResult();
        break;
    }
  }

  void _calculateDistanceAndTime() {
    if (_technicianLocation == null) return;

    _distanceToClient = _calculateDistance(
        _technicianLocation!, _clientLocation);
    _estimatedArrivalMinutes =
        (_distanceToClient / 30 * 60).round().clamp(1, 60);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371;
    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

void _updateMarkers() {
  final l10n = AppLocalizations.of(context);
  _markers = {
    Marker(
      markerId: const MarkerId('client'),
      position: _clientLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: "My Location",
        snippet: "Service localicated here",
      ),
    ),
    if (_technicianLocation != null)
      Marker(
        markerId: const MarkerId('technician'),
        position: _technicianLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: _technicianName,
          snippet: "Technician's current location",
        ),
      ),
  };
  
  // El InfoWindow se mostrará cuando el usuario toque el marcador
  // No necesitamos forzar su visualización automáticamente
}


// ✅ REEMPLAZA TU FUNCIÓN ORIGINAL CON ESTA VERSIÓN MEJORADA
  void _fitMapToShowBothLocations() {
    if (_mapController == null || _technicianLocation == null) return;

    // Calcula la distancia entre los dos puntos en metros
    final distance = _calculateDistance(_clientLocation, _technicianLocation!) * 1000;

    // SI ESTÁN MUY CERCA: Centra el mapa en un solo punto con un zoom alto
    if (distance < 50) { // Menos de 50 metros de distancia
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _clientLocation,
            zoom: 17.0, // Un zoom cercano para ver detalles
          ),
        ),
      );
      return; // Termina la función aquí
    }

    // SI ESTÁN LEJOS: Crea un recuadro que contenga ambos marcadores
    final southwest = LatLng(
      math.min(_clientLocation.latitude, _technicianLocation!.latitude),
      math.min(_clientLocation.longitude, _technicianLocation!.longitude),
    );

    final northeast = LatLng(
      math.max(_clientLocation.latitude, _technicianLocation!.latitude),
      math.max(_clientLocation.longitude, _technicianLocation!.longitude),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southwest, northeast: northeast),
        80.0, // ✅ Un padding más razonable para que se vean bien
      ),
    );
  }
  

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _statusTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 500), () {
                _fitMapToShowBothLocations();
              });
            },
            initialCameraPosition: CameraPosition(
              target: _clientLocation,
              zoom: 17.0,
            ),
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),
          _buildHeader(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildBottomPanel(),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tracking,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _getStatusText(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _showDetails = !_showDetails;
                });
                if (_showDetails) {
                  _slideController.forward();
                } else {
                  _slideController.reverse();
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _showDetails
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (!_showDetails) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTechnicianHeader(),
          _buildServiceInfo(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTechnicianHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.brandBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _technicianName.isNotEmpty
                        ? _technicianName[0].toUpperCase()
                        : 'T',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _technicianName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _technicianRating,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '• $_vehicleInfo',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '$_estimatedArrivalMinutes',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.minutes,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfo() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _technicianLocation != null
                      ? '${l10n.distance}: ${_distanceToClient.toStringAsFixed(1)} km'
                      : l10n.obtainingLocation,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                ),
                child: Text(
                  _getStatusText(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final l10n = AppLocalizations.of(context);
    double progress = _getServiceProgress();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.serviceProgress,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.gray300,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 8,
        ),
      ],
    );
  }
Widget _buildActionButtons() {
  final l10n = AppLocalizations.of(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), // ✅ Más padding inferior
    child: Column(
      children: [
        // ✅ PRIMERA FILA: Llamar y Mensaje
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _callTechnician,
                icon: Icon(Icons.phone, size: 18),
                label: Text(l10n.call),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: BorderSide(color: AppColors.success),
                  padding: const EdgeInsets.symmetric(vertical: 14), // ✅ Más padding vertical
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16), // ✅ Más espacio entre botones
Expanded(
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      SizedBox(
        width: double.infinity, // ✅ FORZAR TODO EL ANCHO
        child: OutlinedButton(
          onPressed: _openChat,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.info,
            side: BorderSide(color: AppColors.info),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // ✅ CENTRAR CONTENIDO
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.message, size: 18),
              const SizedBox(width: 8), // ✅ ESPACIO ENTRE ICONO Y TEXTO
              Text(l10n.message),
            ],
          ),
        ),
      ),
      Consumer<ChatNotificationProvider>(
        builder: (context, notificationProvider, child) {
          final unreadCount = notificationProvider.getUnreadCount(widget.serviceRequest.id);
          if (unreadCount <= 0) return const SizedBox.shrink();
          return Positioned(
            right: 6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    ],
  ),
),          ],
        ),
        
        // ✅ SEGUNDA FILA: Botón de cancelar (si aplica)
        if (widget.canStillCancel) ...[
          const SizedBox(height: 12), // ✅ Espacio entre filas
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showCancelConfirmation();
              },
              icon: Icon(Icons.cancel, size: 18),
              label: Text(l10n.cancel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14), // ✅ Más padding vertical
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
  void _refreshServiceData() async {
    try {
      final updatedRequest = await ServiceRequestService.getRequestStatus(
          widget.serviceRequest.id);
      setState(() {
        _currentRequest = updatedRequest;
        _activeServiceRequest = updatedRequest;
      });
    } catch (e) {
      print('Error refreshing service data: $e');
    }
  }

  void _openChat() async {
    HapticFeedback.lightImpact();
    print('🔍 Opening chat for service: ${widget.serviceRequest.id}');
    print('📱 User: ${widget.serviceRequest.user?.name ?? 'Unknown'}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceChatScreen(
          serviceRequest: widget.serviceRequest,
          userType: 'technician',
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.processing,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    final l10n = AppLocalizations.of(context);
    switch (_currentRequest.status) {
      case 'accepted':
        return l10n.technicianConfirmedPreparing;
      case 'en_route':
        return l10n.enRouteToLocation;
      case 'on_site':
        return l10n.technicianOnSite;
      case 'charging':
        return l10n.chargingVehicle;
      case 'completed':
        return l10n.serviceCompleted;
      default:
        return l10n.preparingService;
    }
  }

  Color _getStatusColor() {
    switch (_currentRequest.status) {
      case 'accepted':
        return Colors.blue;
      case 'en_route':
        return Colors.orange;
      case 'on_site':
        return Colors.green;
      case 'charging':
        return AppColors.primary;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _getServiceProgress() {
    switch (_currentRequest.status) {
      case 'accepted':
        return 0.2;
      case 'en_route':
        return 0.4;
      case 'on_site':
        return 0.6;
      case 'charging':
        return 0.8;
      case 'completed':
        return 1.0;
      default:
        return 0.0;
    }
  }

  void _callTechnician() async {
    final l10n = AppLocalizations.of(context);
    if (_technicianPhone.isNotEmpty) {
      final Uri phoneUri = Uri.parse('tel:$_technicianPhone');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } else {
      _showErrorSnackbar(l10n.phoneNotAvailable);
    }
  }

  void _sendMessage() async {
    final l10n = AppLocalizations.of(context);
    if (_technicianPhone.isNotEmpty) {
      final message =
          'Hola, soy tu cliente de VoltGo. Te escribo respecto al servicio #${_currentRequest.id}';
      final Uri whatsappUri = Uri.parse(
          'https://wa.me/$_technicianPhone?text=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        final Uri smsUri = Uri.parse(
            'sms:$_technicianPhone?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      }
    } else {
      _showErrorSnackbar(l10n.cannotSendMessages);
    }
  }

  void _showCancelConfirmation() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.cancelServiceConfirmation),
        content: Text(l10n.areYouSureCancel),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCancel?.call();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.yesCancel, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStatusAlert(String title, String message, Color color) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  Text(message, style: GoogleFonts.inter(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateBackWithResult() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }
}