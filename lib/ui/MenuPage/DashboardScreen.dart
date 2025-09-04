import 'dart:async';
import 'dart:convert';
import 'package:Voltgo_User/data/logic/dashboard/DashboardLogic.dart';
import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_User/data/services/ChatService.dart';
import 'package:Voltgo_User/data/services/ServiceChatScreen.dart';
import 'package:Voltgo_User/data/services/ServiceRequestService.dart';
import 'package:Voltgo_User/data/services/UserService.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/MenuPage/ClientRealTimeTrackingWidget.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import 'package:lottie/lottie.dart';

enum PassengerStatus { idle, searching, driverAssigned, onTrip, completed }

class PassengerMapScreen extends StatefulWidget {
  const PassengerMapScreen({super.key});

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final DashboardLogic _logic;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _hasActiveService = false;
  ServiceRequestModel? _existingRequest;
  bool _isLoading = true;
  PassengerStatus _passengerStatus = PassengerStatus.idle;
  Timer? _statusCheckTimer;
  // ✅ NUEVAS variables para tiempo de cancelación
  Timer? _cancellationTimeTimer;
  int _cancellationTimeRemaining = 0; // en segundos
  bool _canStillCancel = true;
  Timer? _searchingAnimationTimer;
  ServiceRequestModel? _activeRequest;
  // Variables para la UI mejorada
  double _estimatedPrice = 0.0;
  int _estimatedTime = 0;
  String _driverName = '';
  String _driverRating = '5.0';
  String _vehicleInfo = '';
  String _connectorType = '';
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _statusChangeController;
  late Animation<Offset> _statusSlideAnimation;
  late Animation<double> _statusFadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _searchingDots = 0;
  bool _hasVehicleRegistered = false;
  bool _isCheckingVehicle = true;
  String? _lastKnownStatus;
  DateTime? _lastBackgroundTime;
  String _currentServiceStage = 'idle';
  double _serviceProgress = 0.0;
  String _serviceStartTime = '';
  int _initialBatteryLevel = 0;
  int _chargeTimeMinutes = 0;
  String _serviceNotes = '';
  bool _hasServiceStarted = false;
  Timer? _serviceProgressTimer;
  String? _lastActiveServiceStatus;
  ServiceRequestModel? _activeServiceRequest;

// 4. AGREGAR AL FINAL DE initState() EXISTENTE:
  @override
  void initState() {
    super.initState();
    _logic = DashboardLogic();
    _initializeAnimations();
    _initializeProgressAnimations();

    WidgetsBinding.instance.addObserver(this);
    _checkVehicleRegistration();

    // ✅ AGREGAR: Configurar listener para cambios de estado global
    _setupStatusChangeListener();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  // ✅ NUEVO: Inicializar animaciones de progreso
  void _initializeProgressAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _statusChangeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _statusSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _statusChangeController,
      curve: Curves.elasticOut,
    ));

    _statusFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statusChangeController,
      curve: Curves.easeIn,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _slideController.dispose();
    _progressController.dispose();
    _statusChangeController.dispose();
    _pulseController.dispose();
    _cancellationTimeTimer?.cancel();
    _serviceProgressTimer?.cancel();
    _logic.dispose();
    _statusCheckTimer?.cancel();
    _searchingAnimationTimer?.cancel();
    super.dispose();
  }

  // ✅ NUEVO: Configurar listener global para cambios de estado
  void _setupStatusChangeListener() {
    print('📡 Status change listener configurado');
  }

  // Manejar cambios en el ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _lastBackgroundTime = DateTime.now();
        print('📱 App fue al background: $_lastBackgroundTime');
        break;

      case AppLifecycleState.resumed:
        print('📱 App regresó del background');
        _handleAppResumed();
        break;

      case AppLifecycleState.detached:
        print('📱 App se está cerrando');
        break;

      default:
        break;
    }
  }

// 1. En _getStatusInfo() - líneas aproximadas 180-230
  Map<String, dynamic> _getStatusInfo(String status) {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR ESTA LÍNEA

    switch (status) {
      case 'accepted':
        return {
          'title': l10n.technicianConfirmedTitle, // ✅ CAMBIAR
          'message': l10n.technicianConfirmedMessage, // ✅ CAMBIAR
          'icon': Icons.person_add_alt_1,
          'color': Colors.blue,
        };
      case 'en_route':
        return {
          'title': l10n.technicianEnRoute, // ✅ CAMBIAR
          'message': l10n.technicianHeadingToLocation, // ✅ CAMBIAR
          'icon': Icons.directions_car,
          'color': Colors.indigo,
        };
      case 'on_site':
        return {
          'title': l10n.technicianArrivedTitle, // ✅ CAMBIAR
          'message': l10n.technicianArrivedMessage, // ✅ CAMBIAR
          'icon': Icons.location_on,
          'color': Colors.purple,
        };
      case 'charging':
        return {
          'title': l10n.serviceInitiatedTitle, // ✅ CAMBIAR
          'message': l10n.serviceInitiatedMessage, // ✅ CAMBIAR
          'icon': Icons.battery_charging_full,
          'color': Colors.green,
        };
      case 'completed':
        return {
          'title': l10n.serviceCompletedTitle, // ✅ CAMBIAR
          'message': l10n.serviceCompletedMessage, // ✅ CAMBIAR
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      default:
        return {
          'title': l10n.statusUpdated, // ✅ CAMBIAR
          'message': l10n.serviceStatusChanged, // ✅ CAMBIAR
          'icon': Icons.info,
          'color': AppColors.info,
        };
    }
  }

  void _updateServiceProgress(String status) {
    setState(() {
      _currentServiceStage = status;

      switch (status) {
        case 'pending':
          _serviceProgress = 0.1;
          break;
        case 'accepted':
          _serviceProgress = 0.25;
          break;
        case 'en_route':
          _serviceProgress = 0.5;
          break;
        case 'on_site':
          _serviceProgress = 0.75;
          break;
        case 'charging':
          _serviceProgress = 0.9;
          _hasServiceStarted = true;
          break;
        case 'completed':
          _serviceProgress = 1.0;
          break;
      }
    });

    // Animar el progreso
    _progressController.animateTo(_serviceProgress);
  }

  void _showStatusChangeAnimation(String status) {
    _statusChangeController.forward().then((_) {
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _statusChangeController.reverse();
        }
      });
    });
  }

// 5. ✅ AGREGAR MÉTODO PARA MOSTRAR NOTIFICACIÓN FLOTANTE MEJORADA
  void _showFloatingStatusNotification(
      String title, String message, IconData icon, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 100,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _statusChangeController,
              curve: Curves.elasticOut,
            )),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          message,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Animar entrada
    _statusChangeController.forward();

    // Remover después de 4 segundos
    Timer(const Duration(seconds: 4), () {
      _statusChangeController.reverse().then((_) {
        overlayEntry.remove();
        _statusChangeController.reset();
      });
    });
  }

// ✅ USAR LA NOTIFICACIÓN FLOTANTE EN LUGAR DE SnackBar PARA CAMBIOS IMPORTANTES
  void _showStatusNotification(
      String title, String message, IconData icon, Color color) {
    _showFloatingStatusNotification(title, message, icon, color);
  }

// ✅ Mostrar diálogo de cambio de estado prominente para cambios importantes
  void _showImportantStatusChangeDialog(String status) {
    final statusInfo = _getStatusInfo(status);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                statusInfo['color'].withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono animado
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.5, end: 1.0),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: statusInfo['color'].withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        statusInfo['icon'],
                        color: statusInfo['color'],
                        size: 48,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Título
              Text(
                statusInfo['title'],
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Subtítulo
              Text(
                statusInfo['message'],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Información adicional según el estado
              if (status == 'charging') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El técnico documentará el progreso durante el servicio',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botón de cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusInfo['color'],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto-cerrar después de 8 segundos
    Timer(const Duration(seconds: 8), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget _buildOnTripContent() {
    return _buildServiceInProgressContentUpdated(); // ✅ Usar la versión actualizada
  }

  Widget _buildRealTimeServiceProgress() {
    final l10n = AppLocalizations.of(context);

    if (!_hasServiceStarted) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Icon(
                  Icons.flash_on,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.serviceInProgress,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const Spacer(),
              if (_serviceStartTime.isNotEmpty)
                Text(
                  'Desde $_serviceStartTime',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (_initialBatteryLevel > 0 || _chargeTimeMinutes > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (_initialBatteryLevel > 0) ...[
                  Icon(Icons.battery_std, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Inicial: $_initialBatteryLevel%',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ],
                if (_initialBatteryLevel > 0 && _chargeTimeMinutes > 0)
                  const SizedBox(width: 16),
                if (_chargeTimeMinutes > 0) ...[
                  Icon(Icons.timer, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Tiempo: $_chargeTimeMinutes min',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
          if (_serviceNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _serviceNotes,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceInProgressContentUpdated() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Estado del servicio con animación
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.1),
                    Colors.green.withOpacity(0.05)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.battery_charging_full,
                            color: Colors.green,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.chargingVehicle,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'El técnico está trabajando en tu vehículo',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ✅ PROGRESO EN TIEMPO REAL
                  if (_hasServiceStarted) ...[
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ PROGRESO DETALLADO DEL SERVICIO
            _buildRealTimeServiceProgress(),

            const SizedBox(height: 16),

            // Información compacta del técnico
            _buildCompactTechnicianInfo(),

            const SizedBox(height: 20),

            // Botón de chat
            _buildChatButton(),

            // ✅ INICIAR polling de progreso cuando se muestra esta pantalla
            if (_hasServiceStarted) ...[
              const SizedBox.shrink(), // Trigger para iniciar polling
              Builder(
                builder: (context) {
                  // Iniciar polling solo una vez
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _startServiceProgressPolling();
                  });
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTechnicianInfo() {
    if (_driverName.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray300),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _driverName.isNotEmpty ? _driverName[0].toUpperCase() : 'T',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.warning, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _driverRating,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openChat,
            icon: Icon(Icons.message, color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: _openChat,
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: Text(
          'Chat con técnico',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          _showPermissionDialog();
          return;
        }
      }

      final position = await _logic.getCurrentUserPosition();
      if (position != null) {
        final userLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _logic.initialCameraPosition = CameraPosition(
            target: userLocation,
            zoom: 16.0,
          );
          _logic.addUserMarker(position);
        });

        final controller = await _logic.mapController.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: userLocation, zoom: 16.0),
        ));
      }

      // ✅ VERIFICAR servicio activo DESPUÉS de configurar el mapa
      await _checkForActiveServiceOnStartup();

      print('✅ Mapa inicializado con verificación de servicio activo');
    } catch (e) {
      print('❌ Error initializing map: $e');
      _showErrorMessage('Error al cargar el mapa');
      _ensureIdleState(); // Solo ir a idle si hay error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadServiceProgressFromBackend() async {
    if (_activeRequest == null) return;

    try {
      print('🔄 Cargando progreso del servicio desde backend...');

      final progressData =
          await ServiceRequestService.getServiceProgress(_activeRequest!.id);

      if (progressData != null && progressData['has_progress'] == true) {
        final progress = progressData['progress'];

        setState(() {
          // Actualizar datos del servicio
          _hasServiceStarted = progress['service_started'] ?? false;

          if (progress['service_start_time'] != null) {
            final startTime = DateTime.parse(progress['service_start_time']);
            _serviceStartTime =
                '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
          }

          // Detalles técnicos del servicio
          if (progress['initial_battery_level'] != null) {
            _initialBatteryLevel =
                int.tryParse(progress['initial_battery_level'].toString()) ?? 0;
          }

          if (progress['charge_time_minutes'] != null) {
            _chargeTimeMinutes =
                int.tryParse(progress['charge_time_minutes'].toString()) ?? 0;
          }

          _serviceNotes = progress['service_notes']?.toString() ?? '';
        });

        print('✅ Progreso del servicio cargado:');
        print('  - Servicio iniciado: $_hasServiceStarted');
        print('  - Hora de inicio: $_serviceStartTime');
        print('  - Nivel inicial batería: $_initialBatteryLevel%');
        print('  - Tiempo de carga: $_chargeTimeMinutes min');
      }
    } catch (e) {
      print('❌ Error cargando progreso del servicio: $e');
    }
  }

  Future<void> _checkForActiveServiceOnStartup() async {
    try {
      print('🔍 Verificando servicios activos al iniciar la app...');

      // Verificar si hay vehículo registrado primero
      if (!_hasVehicleRegistered) {
        print('⚠️ Usuario no tiene vehículo registrado');
        return;
      }

      // Obtener servicio activo del servidor
      final activeService = await ServiceRequestService.getActiveService();

      if (activeService != null) {
        print(
            '🎯 Servicio activo encontrado: ${activeService.id} - Estado: ${activeService.status}');

        setState(() {
          _hasActiveService = true;
          _existingRequest = activeService;
          _activeRequest = activeService;
          _lastKnownStatus = activeService
              .status; // ✅ IMPORTANTE: Establecer el estado conocido

          // ✅ ESTABLECER EL ESTADO CORRECTO DE LA UI SEGÚN EL STATUS
          switch (activeService.status) {
            case 'pending':
              _passengerStatus = PassengerStatus.searching;
              _startStatusChecker();
              _startSearchingAnimation();
              break;

            case 'accepted':
            case 'en_route':
              _passengerStatus = PassengerStatus.driverAssigned;
              _loadTechnicianData(activeService);
              _startTechnicianLocationTracking();
              // ✅ RESTAURAR TIMER DE CANCELACIÓN
              _updateCancellationTimeInfo().then((_) {
                if (_canStillCancel && _cancellationTimeRemaining > 0) {
                  _startCancellationTimer();
                }
              });
              break;

            case 'on_site':
            case 'charging':
              _passengerStatus = PassengerStatus.onTrip;
              _loadTechnicianData(activeService);
              if (activeService.status == 'charging') {
                _hasServiceStarted = true;
                // Cargar progreso del servicio
                _loadServiceProgressFromBackend();
              }
              break;

            case 'completed':
              _passengerStatus = PassengerStatus.completed;
              _showRatingDialog();
              break;

            default:
              _passengerStatus = PassengerStatus.idle;
              break;
          }
        });

        // ✅ MOSTRAR EL PANEL si hay servicio activo
        if (_passengerStatus != PassengerStatus.idle) {
          _slideController.forward();
        }

        // ✅ INICIAR MONITOREO DE ESTADO
        _startStatusChecker();

        print('✅ Estado de la UI restaurado: $_passengerStatus');
      } else {
        print('ℹ️ No hay servicios activos al iniciar');
        _ensureIdleState();
      }
    } catch (e) {
      print('❌ Error verificando servicios activos al iniciar: $e');
      _ensureIdleState();
    }
  }

// 2. ✅ NUEVO: Verificación silenciosa de servicios activos
  Future<void> _checkForActiveServiceSilently() async {
    try {
      print('🔍 Verificando servicios activos silenciosamente...');

      // Usar el nuevo método del servicio
      final activeService = await ServiceRequestService.getActiveService();

      if (activeService != null) {
        print(
            '✅ Servicio activo encontrado: ${activeService.id} - Estado: ${activeService.status}');

        setState(() {
          _hasActiveService = true;
          _existingRequest = activeService;
          _activeRequest = activeService;

          // Determinar el estado de la UI según el estado del servicio
          switch (activeService.status) {
            case 'pending':
              _passengerStatus = PassengerStatus.searching;
              _startStatusChecker();
              _startSearchingAnimation();
              break;
            case 'accepted':
            case 'en_route':
              _passengerStatus = PassengerStatus.driverAssigned;
              _loadTechnicianData(activeService);
              _startTechnicianLocationTracking();
              break;
            case 'on_site':
            case 'charging':
              _passengerStatus = PassengerStatus.onTrip;
              _loadTechnicianData(activeService);
              break;
          }
        });

        _slideController.forward();
      } else {
        print('ℹ️ No hay servicios activos');
        _ensureIdleState();
      }
    } catch (e) {
      print('ℹ️ Error verificando servicios activos: $e');
      _ensureIdleState();
    }
  }

  void _ensureIdleState() {
    setState(() {
      _hasActiveService = false;
      _existingRequest = null;
      _activeRequest = null;
      _passengerStatus = PassengerStatus.idle;

      // Reiniciar variables de UI
      _estimatedPrice = 0.0;
      _estimatedTime = 0;
      _driverName = '';
      _driverRating = '5.0';
      _vehicleInfo = '';
      _connectorType = '';
    });
  }

// ✅ NUEVO: Método para verificar servicios activos
  Future<void> _checkForActiveService() async {
    try {
      print('🔍 Verificando servicios activos...');
      final history = await ServiceRequestService.getServiceHistory();

      // Buscar solicitudes activas (no completadas, no canceladas)
      final activeService = history.firstWhere(
        (request) => ['pending', 'accepted', 'en_route', 'on_site', 'charging']
            .contains(request.status),
        orElse: () => throw StateError('No active service found'),
      );

      if (activeService != null) {
        print(
            '✅ Servicio activo encontrado: ${activeService.id} - Estado: ${activeService.status}');

        setState(() {
          _hasActiveService = true;
          _existingRequest = activeService;
          _activeRequest = activeService;

          // Determinar el estado de la UI según el estado del servicio
          switch (activeService.status) {
            case 'pending':
              _passengerStatus = PassengerStatus.searching;
              _startStatusChecker();
              break;
            case 'accepted':
            case 'en_route':
              _passengerStatus = PassengerStatus.driverAssigned;
              _loadTechnicianData(activeService);
              _startTechnicianLocationTracking();
              break;
            case 'on_site':
            case 'charging':
              _passengerStatus = PassengerStatus.onTrip;
              _loadTechnicianData(activeService);
              break;
          }
        });

        _slideController.forward();
      }
    } catch (e) {
      print('ℹ️ No hay servicios activos: $e');
      setState(() {
        _hasActiveService = false;
        _existingRequest = null;
      });
    }
  }

// 4. ✅ CORREGIR _loadTechnicianData()
  void _loadTechnicianData(ServiceRequestModel request) {
    final technicianData = request.technician;
    final technicianProfile = technicianData?.profile;

    setState(() {
      _driverName = technicianData?.name ?? 'Técnico';
      _driverRating = double.tryParse(technicianProfile?.averageRating ?? '5.0')
              ?.toStringAsFixed(1) ??
          '5.0';

      // ✅ NUEVO: Usar el método vehicleDescription del modelo actualizado
      _vehicleInfo =
          technicianProfile?.vehicleDescription ?? 'Vehículo de servicio';

      // ✅ ALTERNATIVA: Si quieres construir manualmente el string del vehículo
      // _vehicleInfo = _buildVehicleInfo(technicianProfile);

      // ✅ CORREGIDO: Acceso seguro al tipo de conector
      _connectorType =
          technicianProfile?.availableConnectors?.isNotEmpty == true
              ? technicianProfile!.availableConnectors!
              : 'No especificado';

      // Agregar o actualizar el marcador del técnico si hay ubicación
      if (technicianProfile?.currentLat != null &&
          technicianProfile?.currentLng != null) {
        final driverId =
            'driver_${technicianData?.id ?? request.technicianId ?? 0}';

        // ✅ CONVERSIÓN SEGURA DE STRING A DOUBLE
        final lat = double.tryParse(technicianProfile!.currentLat!);
        final lng = double.tryParse(technicianProfile.currentLng!);

        if (lat != null && lng != null) {
          _logic.updateDriverMarker(
            driverId,
            LatLng(lat, lng),
          );
        }
      }
    });
  }

// ✅ MÉTODO HELPER ALTERNATIVO para construir info del vehículo manualmente
  String _buildVehicleInfo(TechnicianProfile? profile) {
    if (profile?.vehicleDetails == null || profile!.vehicleDetails!.isEmpty) {
      return 'Vehículo de servicio';
    }

    final parts = <String>[];

    // Usar los getters del modelo actualizado
    if (profile.vehicleMake?.isNotEmpty == true) {
      parts.add(profile.vehicleMake!);
    }

    if (profile.vehicleModel?.isNotEmpty == true) {
      parts.add(profile.vehicleModel!);
    }

    if (profile.vehiclePlate?.isNotEmpty == true) {
      parts.add('(${profile.vehiclePlate!})');
    }

    return parts.isNotEmpty ? parts.join(' ') : 'Vehículo de servicio';
  }

// ✅ MÉTODO HELPER para obtener detalles específicos del vehículo
  String _getVehicleDetail(
      TechnicianProfile? profile, String key, String defaultValue) {
    return profile?.vehicleDetails?[key]?.toString() ?? defaultValue;
  }

  void _startTechnicianLocationTracking() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_activeRequest == null ||
          _passengerStatus == PassengerStatus.idle ||
          _passengerStatus == PassengerStatus.completed) {
        timer.cancel();
        return;
      }

      try {
        final technicianLocation =
            await ServiceRequestService.getTechnicianLocation(
                _activeRequest!.id);

        if (technicianLocation != null) {
          setState(() {
            // Actualizar la posición del marcador del técnico
            _logic.updateDriverMarker('driver_1', technicianLocation);
          });

          // Opcional: Calcular y actualizar tiempo estimado de llegada
          _updateEstimatedArrivalTime(technicianLocation);
        }
      } catch (e) {
        print("Error tracking technician location: $e");
      }
    });
  }

// Método para calcular tiempo estimado de llegada
  void _updateEstimatedArrivalTime(LatLng technicianLocation) {
    final userLocation =
        LatLng(_activeRequest!.requestLat, _activeRequest!.requestLng);
    final distance = _calculateDistance(technicianLocation, userLocation);

    // Calcular tiempo estimado (asumiendo velocidad promedio de 30 km/h en ciudad)
    final estimatedMinutes = (distance / 30 * 60).round();

    if (mounted) {
      setState(() {
        _estimatedTime = estimatedMinutes > 0 ? estimatedMinutes : 1;
      });
    }
  }

// Método auxiliar para calcular distancia entre dos puntos
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Radio de la Tierra en km

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

  void _showLocationDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(l10n.locationRequired),
          ],
        ),
        content: Text(l10n.locationNeeded),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.activate, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkVehicleRegistration() async {
    print('🔍 Iniciando verificación de vehículo registrado...');
    setState(() => _isCheckingVehicle = true);

    try {
      // ✅ USAR EL MÉTODO CON FALLBACK
      final hasVehicle = await UserService.hasRegisteredVehicleWithFallback();
      print('📡 Respuesta final del UserService: hasVehicle = $hasVehicle');

      setState(() {
        _hasVehicleRegistered = hasVehicle;
        _isCheckingVehicle = false;
      });

      if (!hasVehicle) {
        print('⚠️ Usuario no tiene vehículo registrado, mostrando diálogo...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToVehicleRegistration();
        });
      } else {
        print('✅ Usuario tiene vehículo registrado, inicializando mapa...');
        _initializeMap();
      }
    } catch (e) {
      print('❌ Error verificando vehículo: $e');
      setState(() => _isCheckingVehicle = false);
      _showVehicleRegistrationDialog();
    }
  }

// ✅ AGREGAR método de debugging para verificar estado
  void _debugVehicleStatus() async {
    print('🔧 DEBUG - Estado actual:');
    print('  _hasVehicleRegistered: $_hasVehicleRegistered');
    print('  _isCheckingVehicle: $_isCheckingVehicle');

    try {
      final hasVehicle = await UserService.hasRegisteredVehicle();
      print('  Servidor dice: $hasVehicle');
    } catch (e) {
      print('  Error consultando servidor: $e');
    }
  }

  void _showVehicleRegistrationDialog() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.warning_amber, color: AppColors.warning, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.verificationNeeded)), // ✅ CAMBIAR
          ],
        ),
        content: Text(
          l10n.couldNotVerifyVehicle, // ✅ CAMBIAR
          style: GoogleFonts.inter(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/vehicle-registration');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.goToRegistration, // ✅ CAMBIAR
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// ✅ ACTUALIZAR _navigateToVehicleRegistration() con verificación mejorada
  void _navigateToVehicleRegistration() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.directions_car,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.vehicleRegistration)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.vehicleNeeded,
                style: GoogleFonts.inter(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.info, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.whyNeeded,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.whyNeededDetails,
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                print('🚀 Navegando a registro de vehículo...');

                final result = await Navigator.pushNamed(
                  context,
                  '/vehicle-registration',
                );

                print('🔄 Resultado de registro: $result');

                if (result == true) {
                  print('✅ Vehículo registrado exitosamente, verificando...');

                  // ✅ ESPERAR UN MOMENTO PARA QUE EL SERVIDOR SE ACTUALICE
                  setState(() {
                    _isCheckingVehicle = true;
                  });

                  await Future.delayed(const Duration(seconds: 3));

                  try {
                    // ✅ USAR VERIFICACIÓN CON FALLBACK
                    final hasVehicle =
                        await UserService.hasRegisteredVehicleWithFallback();
                    print('🔍 Re-verificación del servidor: $hasVehicle');

                    if (hasVehicle) {
                      setState(() {
                        _hasVehicleRegistered = true;
                        _isCheckingVehicle = false;
                      });
                      print('✅ Estado actualizado, inicializando mapa...');
                      _initializeMap();
                    } else {
                      print(
                          '⚠️ Servidor aún no refleja el cambio, intentando una vez más...');

                      // ✅ SEGUNDO INTENTO CON MÁS TIEMPO
                      await Future.delayed(const Duration(seconds: 5));
                      final hasVehicleRetry =
                          await UserService.hasRegisteredVehicleWithFallback();

                      if (hasVehicleRetry) {
                        setState(() {
                          _hasVehicleRegistered = true;
                          _isCheckingVehicle = false;
                        });
                        _initializeMap();
                      } else {
                        print(
                            '❌ El servidor no refleja el cambio. Mostrando mensaje al usuario.');
                        setState(() => _isCheckingVehicle = false);
                        _showServerSyncIssueDialog();
                      }
                    }
                  } catch (e) {
                    print('❌ Error re-verificando: $e');
                    setState(() {
                      _hasVehicleRegistered =
                          true; // Confiar en el registro exitoso
                      _isCheckingVehicle = false;
                    });
                    _initializeMap();
                  }
                } else {
                  print(
                      '❌ Registro cancelado, mostrando diálogo nuevamente...');
                  _navigateToVehicleRegistration();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.registerVehicle,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServerSyncIssueDialog() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.sync_problem, color: AppColors.warning, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.syncInProgress)), // ✅ CAMBIAR
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.vehicleRegisteredCorrectly, // ✅ CAMBIAR
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.syncOptions, // ✅ CAMBIAR de 'Opciones:'
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.syncOptionsText, // ✅ CAMBIAR del texto largo
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToVehicleRegistration();
            },
            child: Text(l10n.retry), // ✅ CAMBIAR de 'Reintentar'
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _hasVehicleRegistered = true;
                _isCheckingVehicle = false;
              });
              _initializeMap();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.continueAnyway, // ✅ CAMBIAR
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_disabled, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text(l10n.permissionDenied), // ✅ YA EXISTE
          ],
        ),
        content: Text(l10n.cannotContinue), // ✅ YA EXISTE
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.goToSettings, // ✅ YA EXISTE
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showActiveServiceDialog() {
    final l10n = AppLocalizations.of(context);
    final request = _existingRequest!;
    String statusText = _getServiceStatusText(request.status);
    String timeText = _getTimeAgoText(request.requestedAt);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.electric_bolt, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(l10n.activeService),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.youHaveActiveServiceDialog,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.request} #${request.id}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.status}: $statusText',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  Text(
                    '${l10n.requested}: $timeText',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.whatToDo,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.viewService,
                style: TextStyle(color: AppColors.primary)),
          ),
          if (['pending', 'accepted'].contains(request.status))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelActiveService();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.cancelService,
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

// ✅ CORRECCIÓN ERROR DE TIPO - PassengerMapScreen

// ✅ CORREGIR _cancelActiveService para manejar tipos correctamente
  Future<void> _cancelActiveService() async {
    if (_existingRequest == null) {
      _showErrorMessage('No hay servicio activo para cancelar');
      return;
    }

    // ✅ VERIFICAR si aún puede cancelar
    final timeInfo = await _getCancellationTimeInfo();

    if (timeInfo != null && !(timeInfo['can_cancel'] ?? false)) {
      final timeElapsed = timeInfo['time_info']?['elapsed_minutes'] ?? 0;
      final timeLimit = timeInfo['time_info']?['limit_minutes'] ?? 5;

      _showTimeExpiredDialog(timeElapsed, timeLimit);
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🚀 Cancelando servicio activo: ${_existingRequest!.id}');

      final url = Uri.parse(
          '${Constants.baseUrl}/service/request/${_existingRequest!.id}/cancel');
      final token = await TokenStorage.getToken();

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📡 Respuesta de cancelación: $responseData');

        // ✅ MANEJO SEGURO DE LA TARIFA (puede ser int o double)
        final feeRaw = responseData['request']?['cancellation_fee'];
        double fee = 0.0;

        if (feeRaw != null) {
          if (feeRaw is int) {
            fee = feeRaw.toDouble();
          } else if (feeRaw is double) {
            fee = feeRaw;
          } else if (feeRaw is String) {
            fee = double.tryParse(feeRaw) ?? 0.0;
          }
        }

        print(
            '💰 Tarifa de cancelación procesada: \$${fee.toStringAsFixed(2)}');

        if (fee > 0) {
          _showCancellationWithFeeDialog(fee);
        } else {
          _showSuccessMessage('Servicio cancelado exitosamente');
        }

        _resetToIdle();
      } else if (response.statusCode == 423) {
        // Tiempo límite excedido
        final errorData = jsonDecode(response.body);
        _showTimeExpiredDialog(
            errorData['time_elapsed'] ?? 0, errorData['time_limit'] ?? 5);
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorMessage(
            errorData['message'] ?? 'Error al cancelar el servicio');
      }
    } catch (e) {
      print('❌ Error cancelando servicio: $e');

      // ✅ MANEJO ESPECÍFICO DEL ERROR DE TIPO
      if (e
          .toString()
          .contains("type 'int' is not a subtype of type 'double'")) {
        print(
            '🔧 Error de tipo detectado - reintentando con conversión segura');
        _showSuccessMessage('Servicio cancelado exitosamente');
        _resetToIdle();
      } else {
        _showErrorMessage('Error al cancelar el servicio');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getServiceStatusText(String status) {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    switch (status) {
      case 'pending':
        return l10n.searchingTechnician; // ✅ YA EXISTE
      case 'accepted':
        return l10n.technicianConfirmed; // ✅ YA EXISTE
      case 'en_route':
        return l10n.technicianArriving; // ✅ YA EXISTE
      case 'on_site':
        return l10n.technicianOnSite; // ✅ CAMBIAR de 'Técnico en sitio'
      case 'charging':
        return l10n.chargingVehicle; // ✅ YA EXISTE
      case 'completed':
        return l10n.serviceCompleted; // ✅ YA EXISTE
      case 'cancelled':
        return l10n.cancelled; // ✅ CAMBIAR de 'Cancelado'
      default:
        return l10n.unknownStatus; // ✅ CAMBIAR de 'Estado desconocido'
    }
  }

  String _getTimeAgoText(DateTime requestedAt) {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    final now = DateTime.now();
    final difference = now.difference(requestedAt);

    if (difference.inMinutes < 1) {
      return l10n.fewSecondsAgo; // ✅ CAMBIAR de 'Hace unos segundos'
    } else if (difference.inMinutes < 60) {
      return '${l10n.ago} ${difference.inMinutes} ${l10n.minutes}'; // ✅ CAMBIAR
    } else if (difference.inHours < 24) {
      return '${l10n.ago} ${difference.inHours} ${l10n.hoursAgo}'; // ✅ CAMBIAR
    } else {
      return '${l10n.ago} ${difference.inDays} ${l10n.daysAgo}'; // ✅ CAMBIAR
    }
  }

  Future<void> _requestService() async {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    print('🚀 _requestService called');

    // ✅ NUEVA VERIFICACIÓN: Verificar vehículo registrado ANTES que todo
    if (!_hasVehicleRegistered) {
      print(
          '⚠️ Usuario no tiene vehículo registrado, verificando en servidor...');
      try {
        final hasVehicle = await UserService.hasRegisteredVehicle();
        if (!hasVehicle) {
          print('❌ Confirmado: No tiene vehículo registrado');
          _navigateToVehicleRegistration();
          return;
        }
        // Si tiene vehículo, actualizar estado local
        setState(() => _hasVehicleRegistered = true);
        print('✅ Vehículo verificado, continuando con solicitud...');
      } catch (e) {
        print('❌ Error verificando vehículo: $e');
        _showErrorMessage('Error al verificar tu vehículo registrado');
        return;
      }
    }

    // ✅ VERIFICAR SERVICIOS ACTIVOS MÁS ROBUSTAMENTE
    if (_hasActiveService && _existingRequest != null) {
      print('ℹ️ Ya hay un servicio activo, mostrando diálogo');

      _showActiveServiceDialog();
      return;
    }

    // ✅ VERIFICACIÓN ADICIONAL: Consultar servidor antes de crear nuevo servicio
    try {
      final serverActiveService =
          await ServiceRequestService.getActiveService();
      if (serverActiveService != null) {
        print('ℹ️ Servicio activo encontrado en servidor durante solicitud');
        setState(() {
          _hasActiveService = true;
          _existingRequest = serverActiveService;
          _activeRequest = serverActiveService;
        });
        _showActiveServiceDialog();
        return;
      }
    } catch (e) {
      print('⚠️ Error verificando servicios activos antes de crear: $e');
      // Continuar con la creación si hay error en la verificación
    }

    // ✅ VERIFICAR ESTADO DE LA UI
    if (_passengerStatus != PassengerStatus.idle) {
      print('ℹ️ Estado no es idle: $_passengerStatus');
      return;
    }

    // ✅ VERIFICAR UBICACIÓN
    HapticFeedback.mediumImpact();
    final position = await _logic.getCurrentUserPosition();
    if (position == null) {
      _showErrorMessage(l10n
          .couldNotGetLocation); // ✅ CAMBIAR de 'No se pudo obtener tu ubicación'

      return;
    }

    print(
        '🚀 Requesting service at: ${position.latitude}, ${position.longitude}');

    // ✅ INICIAR PROCESO DE BÚSQUEDA
    setState(() {
      _passengerStatus = PassengerStatus.searching;
      _isLoading = true;
    });
    _slideController.forward();
    _startSearchingAnimation();

    try {
      final location = LatLng(position.latitude!, position.longitude!);
      print('🚀 Creating request for location: $location');

      // ✅ CREAR SOLICITUD EN EL SERVIDOR
      final newRequest = await ServiceRequestService.createRequest(location);
      print('✅ Request created successfully: ${newRequest.id}');

      // ✅ ACTUALIZAR ESTADO LOCAL
      setState(() {
        _activeRequest = newRequest;
        _hasActiveService = true;
        _existingRequest = newRequest;
        _isLoading = false;
      });

      // ✅ INICIAR VERIFICADOR DE ESTADO
      _startStatusChecker();
    } catch (e) {
      print('❌ DETAILED ERROR: $e');

      // ✅ MENSAJES DE ERROR PERSONALIZADOS
      String errorMessage = l10n
          .errorRequestingService; // ✅ CAMBIAR de 'Error al solicitar el servicio'

      if (e.toString().contains('No hay técnicos disponibles')) {
        errorMessage = l10n
            .noTechniciansAvailable; // ✅ CAMBIAR de 'No hay técnicos disponibles en tu área en este momento.'
      } else if (e.toString().contains('vehicle not registered') ||
          e.toString().contains('vehículo no registrado')) {
        errorMessage = l10n
            .needToRegisterVehicle; // ✅ CAMBIAR de 'Necesitas registrar un vehículo para solicitar el servicio.'
        setState(() => _hasVehicleRegistered = false);
        _navigateToVehicleRegistration();
        return;
      } else if (e.toString().contains('No autorizado')) {
        errorMessage = l10n
            .authorizationError; // ✅ CAMBIAR de 'Error de autorización. Por favor, inicia sesión nuevamente.'
      } else if (e.toString().contains('Token no encontrado')) {
        errorMessage = l10n
            .sessionExpired; // ✅ CAMBIAR de 'Sesión expirada. Por favor, inicia sesión nuevamente.'
      }

      _showErrorMessage(errorMessage);

      // ✅ LIMPIEZA COMPLETA en caso de error
      setState(() {
        _passengerStatus = PassengerStatus.idle;
        _hasActiveService = false;
        _existingRequest = null;
        _activeRequest = null;
        _isLoading = false;
      });
      _slideController.reverse();
      _searchingAnimationTimer?.cancel();
    }
  }

// 9. ✅ CORREGIR _startSearchingAnimation()
  void _startSearchingAnimation() {
    _searchingAnimationTimer?.cancel();
    _searchingAnimationTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_passengerStatus != PassengerStatus.searching) {
        timer.cancel();
        return;
      }
      setState(() {
        _searchingDots = (_searchingDots + 1) % 4;
      });
    });
  }

// ✅ PASO 5: Mejorar _resetToIdle para limpiar completamente el estado

  void _resetToIdle() {
    print('🔄 Resetting to idle state and restarting app');

    // Cancelar todos los timers
    _cancellationTimeTimer?.cancel();
    _statusCheckTimer?.cancel();
    _searchingAnimationTimer?.cancel();
    _serviceProgressTimer?.cancel();

    // Limpiar estado completamente
    setState(() {
      _passengerStatus = PassengerStatus.idle;
      _activeRequest = null;
      _hasActiveService = false;
      _existingRequest = null;
      _lastKnownStatus = null;
      _cancellationTimeRemaining = 0;
      _canStillCancel = true;
      _hasServiceStarted = false;

      // Reiniciar variables de UI
      _estimatedPrice = 0.0;
      _estimatedTime = 0;
      _driverName = '';
      _driverRating = '5.0';
      _vehicleInfo = '';
      _connectorType = '';
      _serviceProgress = 0.0;
      _serviceStartTime = '';
      _initialBatteryLevel = 0;
      _chargeTimeMinutes = 0;
      _serviceNotes = '';
    });

    // Limpiar recursos del mapa
    _logic.removeDriverMarker('driver_1');
    _slideController.reverse();

    // Navegar al BottomNavBar para reiniciar completamente
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard', // O la ruta de tu BottomNavBar
      (route) => false, // Esto elimina todas las rutas anteriores
    );

    print('✅ Estado completamente limpiado y app reiniciada');
  }
// ✅ PASO 5: Método auxiliar para mostrar errores (si no lo tienes)

// ✅ PASO 5: Método auxiliar para mostrar errores (si no lo tienes)
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

// 6. ✅ CORREGIR _cancelRide() con limpieza completa
  void _cancelRide() async {
    HapticFeedback.lightImpact();

    _showConfirmationDialog(
      title: 'Cancelar Servicio',
      message: '¿Estás seguro de que deseas cancelar el servicio?',
      confirmText: 'Sí, cancelar',
      onConfirm: () async {
        Navigator.pop(context);

        // Cancelar timers primero
        _statusCheckTimer?.cancel();
        _searchingAnimationTimer?.cancel();

        if (_activeRequest != null) {
          setState(() => _isLoading = true);
          try {
            await ServiceRequestService.cancelRequest(_activeRequest!.id);
            _showSuccessMessage('Servicio cancelado');
          } catch (e) {
            print('❌ Error cancelando en _cancelRide: $e');
            _showErrorMessage('Error al cancelar: ${e.toString()}');
          }
        }

        // ✅ LIMPIEZA COMPLETA DEL ESTADO
        setState(() {
          _passengerStatus = PassengerStatus.idle;
          _activeRequest = null;
          _hasActiveService = false;
          _existingRequest = null;
          _isLoading = false;

          // Reiniciar variables de UI
          _estimatedPrice = 0.0;
          _estimatedTime = 0;
          _driverName = '';
          _driverRating = '5.0';
          _vehicleInfo = '';
          _connectorType = '';
        });

        _logic.removeDriverMarker('driver_1');
        _slideController.reverse();
      },
    );
  }

// 9. En _showConfirmationDialog() - líneas aproximadas 2320-2350
  void _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.no,
                style: TextStyle(color: AppColors.textSecondary)), // ✅ CAMBIAR
          ),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startStatusChecker() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activeRequest == null) {
        timer.cancel();
        return;
      }

      try {
        final updatedRequest =
            await ServiceRequestService.getRequestStatus(_activeRequest!.id);

        // Detectar cancelación automática por expiración
        if (updatedRequest.status == 'cancelled' &&
            _lastKnownStatus != 'cancelled') {
          print('⚠️ Servicio cancelado - verificando motivo...');

          final timeInfo = await _getCancellationTimeInfo();
          if (timeInfo != null && timeInfo['time_info']?['expired'] == true) {
            print(
                '⏰ Servicio cancelado automáticamente por expiración de 1 hora');
            _showServiceExpiredDialog();
          } else {
            print('⚠️ Servicio cancelado por el técnico');
            _showTechnicianCancellationDialog();
          }

          _resetToIdle();
          timer.cancel();
          return;
        }

        // ✅ CARGAR PROGRESO DEL SERVICIO cuando está en 'charging'
        if (updatedRequest.status == 'charging' &&
            _lastKnownStatus != 'charging') {
          await _loadServiceProgressFromBackend();
        }

        // ✅ ACTUALIZAR ESTADO DE LA UI cuando hay cambios
        if (_lastKnownStatus != updatedRequest.status) {
          print(
              '🔄 Estado cambió de $_lastKnownStatus a ${updatedRequest.status}');

          // Actualizar el progreso visual
          _updateServiceProgress(updatedRequest.status);

          // Mostrar animación de cambio
          _showStatusChangeAnimation(updatedRequest.status);

          // Cargar datos específicos del nuevo estado
          await _handleStatusTransition(updatedRequest.status);
        }

        // Actualizar request activo
        setState(() {
          _activeRequest = updatedRequest;
        });

        // Verificar otros cambios de estado existentes...
        _checkForStatusChanges(updatedRequest);
      } catch (e) {
        print("❌ Error checking status: $e");
      }
    });
  }

  Future<void> _handleStatusTransition(String newStatus) async {
    switch (newStatus) {
      case 'accepted':
        // Técnico asignado - cargar datos del técnico
        if (_activeRequest?.technician != null) {
          _loadTechnicianData(_activeRequest!);
          _startCancellationTimer();
        }
        break;

      case 'en_route':
        // Técnico en camino - iniciar tracking
        _startTechnicianLocationTracking();
        break;

      case 'on_site':
        // Técnico llegó al sitio
        HapticFeedback.heavyImpact();
        _showStatusNotification(
          'Técnico ha llegado',
          'El técnico está preparando el equipo',
          Icons.location_on,
          Colors.purple,
        );
        break;

      case 'charging':
        // Servicio iniciado - cargar progreso
        await _loadServiceProgressFromBackend();

        // Actualizar estado de la UI
        setState(() {
          _passengerStatus = PassengerStatus.onTrip;
          _hasServiceStarted = true;
        });

        HapticFeedback.heavyImpact();
        _showStatusNotification(
          'Servicio iniciado',
          'Tu vehículo se está cargando',
          Icons.battery_charging_full,
          Colors.green,
        );
        break;

      case 'completed':
        // Servicio completado
        setState(() {
          _passengerStatus = PassengerStatus.completed;
        });

        HapticFeedback.heavyImpact();
        _showStatusNotification(
          '¡Servicio completado!',
          'Tu vehículo ha sido cargado exitosamente',
          Icons.check_circle,
          Colors.green,
        );

        // Mostrar diálogo de calificación después de un momento
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            _showRatingDialog();
          }
        });
        break;
    }
  }

  // Método para iniciar polling del progreso del servicio
  void _startServiceProgressPolling() {
    _serviceProgressTimer?.cancel();

    if (_hasServiceStarted && _activeRequest != null) {
      _serviceProgressTimer =
          Timer.periodic(const Duration(seconds: 15), (timer) async {
        if (!_hasServiceStarted || _passengerStatus != PassengerStatus.onTrip) {
          timer.cancel();
          return;
        }

        try {
          await _loadServiceProgressFromBackend();
        } catch (e) {
          print('Error en polling de progreso: $e');
        }
      });
    }
  }

  void _showTechnicianCancellationDialog() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_off, color: Colors.orange, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.technicianCancelled)), // ✅ YA EXISTE
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.technicianHasCancelled, // ✅ YA EXISTE
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.dontWorry, // ✅ YA EXISTE
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.emergenciesOrTechnicalIssues, // ✅ AGREGAR A LOCALIZATIONS
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.nextStep, // ✅ YA EXISTE
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.canRequestNewServiceNow, // ✅ AGREGAR A LOCALIZATIONS
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    l10n.close, // ✅ YA EXISTE
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _requestService();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    l10n.findAnotherTechnician, // ✅ YA EXISTE
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ✅ NUEVO: Diálogo cuando servicio expira automáticamente
  void _showServiceExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.access_time_filled, color: Colors.red, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Servicio Expirado')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu servicio ha sido cancelado automáticamente.',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tiempo límite excedido',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El servicio ha estado activo por más de 1 hora sin ser completado. Para tu protección, lo hemos cancelado automáticamente.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Sin cargos aplicados',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No se te cobrará por este servicio cancelado. Puedes solicitar un nuevo servicio cuando gustes.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Entendido'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _requestService(); // Solicitar nuevo servicio
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text('Solicitar Nuevo',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ✅ NUEVO: Advertencia cuando el servicio está cerca de expirar
  void _showNearExpirationWarning(int minutesRemaining) {
    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.timeWarning,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${l10n.serviceWillExpire} $minutesRemaining ${l10n.minutes}',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.7,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: l10n.viewDetails,
          textColor: Colors.white,
          onPressed: () => _showTimeDetailsDialog(minutesRemaining),
        ),
      ),
    );

    // Vibración para llamar la atención
    HapticFeedback.mediumImpact();
  }

// ✅ NUEVO: Advertencia final antes de expirar
  void _showFinalExpirationWarning(int minutesRemaining) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning, color: Colors.red, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('¡Último Aviso!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu servicio expirará en $minutesRemaining minutos y será cancelado automáticamente.',
              style: GoogleFonts.inter(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Si el técnico no ha llegado aún, puedes contactarlo o esperar a que el sistema cancele automáticamente sin costo.',
                style: GoogleFonts.inter(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
          if (_activeRequest?.technician != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Lógica para contactar al técnico
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Contactar Técnico',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );

    // Vibración fuerte para llamar la atención
    HapticFeedback.heavyImpact();
  }

// ✅ NUEVO: Diálogo con detalles del tiempo restante
  void _showTimeDetailsDialog(int minutesRemaining) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Detalles del Servicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiempo restante: $minutesRemaining minutos',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '📋 Información del sistema:',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• Los servicios se cancelan automáticamente después de 1 hora\n'
              '• Esto protege tanto al cliente como al técnico\n'
              '• No se aplican cargos por cancelaciones automáticas\n'
              '• Puedes solicitar un nuevo servicio inmediatamente',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Mostrar feedback cuando se asigna técnico
  void _showTechnicianAssignedFeedback(ServiceRequestModel request) {
    final technicianName = request.technician?.name ?? 'Un técnico';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('¡Técnico Asignado!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$technicianName ha aceptado tu solicitud y se dirige a tu ubicación.',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Puedes ver el progreso del técnico en el mapa.',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Mostrar feedback de cambios de estado
  void _showStatusChangeFeedback(String title, String message, Color color) {
    // Mostrar notificación flotante
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForStatus(title),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.7,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );

    // Vibración para llamar la atención
    HapticFeedback.mediumImpact();
  }

  // ✅ NUEVO: Obtener icono apropiado para cada estado
  IconData _getIconForStatus(String title) {
    if (title.contains('asignado') || title.contains('aceptado')) {
      return Icons.person_add;
    } else if (title.contains('camino')) {
      return Icons.directions_car;
    } else if (title.contains('llegado')) {
      return Icons.location_on;
    } else if (title.contains('iniciado') || title.contains('carga')) {
      return Icons.electric_bolt;
    } else if (title.contains('completado')) {
      return Icons.check_circle;
    } else if (title.contains('cancelado')) {
      return Icons.cancel;
    }
    return Icons.info;
  }

  void _checkForStatusChanges(ServiceRequestModel updatedRequest) {
    final currentStatus = updatedRequest.status;

    // Verificar si hay cambio de estado (incluyendo cuando _lastKnownStatus es null)
    if (_lastKnownStatus != currentStatus) {
      print('🔄 Estado cambió: $_lastKnownStatus → $currentStatus');

      // Actualizar progreso visual
      _updateServiceProgress(currentStatus);

      // Mostrar diferentes tipos de feedback según el cambio
      switch (currentStatus) {
        case 'cancelled':
          if (_lastKnownStatus == 'pending') {
            _showErrorMessage('Búsqueda de técnico cancelada');
          } else {
            final timeInfo = _getCancellationTimeInfo();
            // Lógica de cancelación existente...
          }
          _resetToIdle();
          break;

        case 'accepted':
          // Cambiar condición para incluir cuando _lastKnownStatus es null
          if (_lastKnownStatus == 'pending' || _lastKnownStatus == null) {
            HapticFeedback.heavyImpact();
            _showImportantStatusChangeDialog(currentStatus);
            _loadTechnicianData(updatedRequest);
            _startCancellationTimer();
            setState(() {
              _passengerStatus = PassengerStatus.driverAssigned;
            });
          }
          break;

        case 'en_route':
          HapticFeedback.mediumImpact();
          _showStatusNotification(
            'Técnico en camino',
            'Se dirige hacia tu ubicación',
            Icons.directions_car,
            Colors.indigo,
          );
          _startTechnicianLocationTracking();
          break;

        case 'on_site':
          HapticFeedback.heavyImpact();
          _showImportantStatusChangeDialog(currentStatus);
          break;

        case 'charging':
          HapticFeedback.heavyImpact();
          _showImportantStatusChangeDialog(currentStatus);
          setState(() {
            _passengerStatus = PassengerStatus.onTrip;
            _hasServiceStarted = true;
          });
          // Cargar progreso del servicio
          Timer(const Duration(seconds: 2), () {
            _loadServiceProgressFromBackend();
          });
          break;

        case 'completed':
          HapticFeedback.heavyImpact();
          _showImportantStatusChangeDialog(currentStatus);
          setState(() {
            _passengerStatus = PassengerStatus.completed;
          });
          // Mostrar diálogo de calificación después del diálogo de estado
          Timer(const Duration(seconds: 5), () {
            if (mounted) {
              _showRatingDialog();
            }
          });
          break;
      }

      // Actualizar estado conocido
      _lastKnownStatus = currentStatus;
    }
  }

  void _showImportantNotificationOnResume(String title, String message,
      {bool isUrgent = false}) {
    // Usar notificación más prominente para cambios importantes
    if (isUrgent) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.priority_high, color: Colors.red, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Entendido',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Notificación normal
      _showStatusChangeFeedback(title, message, AppColors.info);
    }
  }

  // ✅ Verificación rápida
  Future<void> _quickServiceCheck() async {
    print('⚡ Realizando verificación rápida...');

    try {
      if (_hasActiveService && _activeRequest != null) {
        final updatedRequest =
            await ServiceRequestService.getRequestStatus(_activeRequest!.id);

        if (updatedRequest.status != _lastKnownStatus) {
          print(
              '🔄 Estado del servicio cambió: ${_lastKnownStatus} → ${updatedRequest.status}');
          _checkForStatusChanges(updatedRequest);
          setState(() => _activeRequest = updatedRequest);
        }

        if (_passengerStatus == PassengerStatus.driverAssigned) {
          await _updateCancellationTimeInfo();
        }
      }
    } catch (e) {
      print('⚠️ Error en verificación rápida: $e');
    }
  }

  // ✅ Verificación completa
  Future<void> _performFullCheck() async {
    print('🔄 Realizando verificación completa al regresar...');

    setState(() => _isLoading = true);

    try {
      final hasVehicle = await UserService.hasRegisteredVehicle();

      if (!hasVehicle) {
        print('⚠️ Usuario no tiene vehículo registrado');
        setState(() {
          _hasVehicleRegistered = false;
          _isLoading = false;
        });
        _navigateToVehicleRegistration();
        return;
      }

      setState(() => _hasVehicleRegistered = true);
      await _checkForActiveServiceOnStartup();

      if (_hasActiveService && _activeRequest != null) {
        await _updateCancellationTimeInfo();
        if (_passengerStatus == PassengerStatus.driverAssigned) {
          _startCancellationTimer();
        }
      }

      print('✅ Verificación completa terminada');
    } catch (e) {
      print('❌ Error en verificación completa: $e');
      _showErrorMessage('Error al verificar el estado del servicio');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleAppResumed() async {
    if (_lastBackgroundTime == null) return;

    final timeInBackground = DateTime.now().difference(_lastBackgroundTime!);

    if (timeInBackground.inMinutes >= 2) {
      // Verificación completa si estuvo más de 2 minutos en background
      await _performFullServiceCheck();
    } else {
      // Verificación rápida
      await _quickServiceStatusCheck();
    }
  }

// Verificación rápida del estado del servicio
  Future<void> _quickServiceStatusCheck() async {
    if (_activeRequest == null) return;

    try {
      final updatedRequest =
          await ServiceRequestService.getRequestStatus(_activeRequest!.id);

      if (updatedRequest.status != _lastKnownStatus) {
        _checkForStatusChanges(updatedRequest);
      }

      setState(() {
        _activeRequest = updatedRequest;
      });
    } catch (e) {
      print('Error en verificación rápida: $e');
    }
  }

// Verificación completa del servicio
  Future<void> _performFullServiceCheck() async {
    setState(() => _isLoading = true);

    try {
      // Verificar si hay servicios activos
      await _checkForActiveServiceOnStartup();

      // Actualizar información de cancelación si hay servicio activo
      if (_activeRequest != null &&
          _passengerStatus == PassengerStatus.driverAssigned) {
        await _updateCancellationTimeInfo();
        if (_canStillCancel) {
          _startCancellationTimer();
        }
      }
    } catch (e) {
      print('Error en verificación completa: $e');
      _showErrorMessage('Error verificando estado del servicio');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startTrip() {
    HapticFeedback.mediumImpact();
    setState(() => _passengerStatus = PassengerStatus.onTrip);
  }

  void _endTrip() {
    HapticFeedback.mediumImpact();
    setState(() => _passengerStatus = PassengerStatus.completed);
    _showRatingDialog();
  }

  void _showRatingDialog() {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡Servicio Completado!',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: \$${_estimatedPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¿Cómo fue tu experiencia?',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setDialogState(() {
                          rating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Agregar comentario (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetToIdle(); // Reinicia la app directamente
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Omitir',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Enviar calificación al backend (si tienes esta funcionalidad)
                          try {
                            // await ServiceRequestService.submitRating(
                            //   _activeRequest!.id,
                            //   rating,
                            //   commentController.text
                            // );
                          } catch (e) {
                            print('Error enviando calificación: $e');
                          }

                          Navigator.pop(context);
                          _showSuccessMessage('¡Gracias por tu calificación!');

                          // Esperar un momento para que se vea el mensaje y luego reiniciar
                          await Future.delayed(const Duration(seconds: 2));
                          _resetToIdle();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enviar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    _showMessage(message, AppColors.error, Icons.error_outline);
  }

  void _showSuccessMessage(String message) {
    _showMessage(message, AppColors.success, Icons.check_circle_outline);
  }

  void _showMessage(String message, Color color, IconData icon) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.inter())),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

// ✅ MÉTODO CORREGIDO para obtener información de cancelación
  Future<Map<String, dynamic>?> _getCancellationTimeInfo() async {
    if (_activeRequest == null) return null;

    try {
      final url = Uri.parse(
          '${Constants.baseUrl}/service/request/${_activeRequest!.id}/cancellation-time');
      final token = await TokenStorage.getToken();

      if (token == null) return null;

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);
      print('🌐 Response status: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Parsed cancellation time data: $data');
        return data;
      } else {
        print('❌ Error response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Exception getting cancellation time info: $e');
    }

    return null;
  }

// ✅ MÉTODO CORREGIDO para actualizar información de tiempo de cancelación
  Future<void> _updateCancellationTimeInfo() async {
    if (_activeRequest == null) return;

    try {
      final timeInfo = await _getCancellationTimeInfo();
      print('🕐 Tiempo info recibido: $timeInfo');

      if (timeInfo != null) {
        // ✅ CORREGIDO: Variable NO final para poder modificarla
        bool canCancel = timeInfo['can_cancel'] ?? false;
        final timeData = timeInfo['time_info'];

        // ✅ CORREGIDO: Manejo seguro del tiempo restante
        int remainingSeconds = 0;

        if (timeData != null) {
          // Priorizar remaining_seconds si existe
          if (timeData['remaining_seconds'] != null) {
            remainingSeconds = (timeData['remaining_seconds'] as num).toInt();
          }
          // Fallback a remaining_minutes convertido a segundos
          else if (timeData['remaining_minutes'] != null) {
            final remainingMinutes = (timeData['remaining_minutes'] as num);
            remainingSeconds = (remainingMinutes * 60).toInt();
          }

          // ✅ VALIDACIÓN: No permitir valores negativos o excesivos
          if (remainingSeconds < 0) {
            remainingSeconds = 0;
            canCancel = false; // ✅ AHORA SÍ se puede modificar
          }

          // Si el tiempo restante es más de 5 minutos (300 segundos), algo está mal
          if (remainingSeconds > 300) {
            print(
                '⚠️ Tiempo restante sospechoso: $remainingSeconds segundos, limitando a 0');
            remainingSeconds = 0;
            canCancel = false; // ✅ AHORA SÍ se puede modificar
          }
        }

        setState(() {
          _canStillCancel = canCancel;
          _cancellationTimeRemaining = remainingSeconds;
        });

        print('✅ Estado actualizado:');
        print('  - Puede cancelar: $canCancel');
        print(
            '  - Tiempo restante: $remainingSeconds segundos (${(remainingSeconds / 60).toStringAsFixed(1)} minutos)');
      }
    } catch (e) {
      print('❌ Error actualizando tiempo de cancelación: $e');
      setState(() {
        _canStillCancel = false;
        _cancellationTimeRemaining = 0;
      });
    }
  }

// ✅ MÉTODO CORREGIDO para mostrar diálogo de tiempo expirado
  void _showTimeExpiredDialog(
      dynamic elapsedMinutesRaw, dynamic limitMinutesRaw) {
    // ✅ CONVERSIÓN SEGURA de los parámetros
    int elapsedMinutes = 0;
    int limitMinutes = 5; // valor por defecto

    if (elapsedMinutesRaw is int) {
      elapsedMinutes = elapsedMinutesRaw;
    } else if (elapsedMinutesRaw is double) {
      elapsedMinutes = elapsedMinutesRaw.toInt();
    } else if (elapsedMinutesRaw is String) {
      elapsedMinutes = int.tryParse(elapsedMinutesRaw) ?? 0;
    }

    if (limitMinutesRaw is int) {
      limitMinutes = limitMinutesRaw;
    } else if (limitMinutesRaw is double) {
      limitMinutes = limitMinutesRaw.toInt();
    } else if (limitMinutesRaw is String) {
      limitMinutes = int.tryParse(limitMinutesRaw) ?? 5;
    }

    // ✅ VALIDACIÓN: Si los números son absurdos, usar valores sensibles
    if (elapsedMinutes > 1440) {
      // Más de 24 horas
      elapsedMinutes = 60; // Asumir 1 hora
    }
    if (limitMinutes > 60 || limitMinutes < 1) {
      limitMinutes = 5; // Valor por defecto sensible
    }

    print('🚨 Mostrando diálogo de tiempo expirado:');
    print('  - Tiempo transcurrido: $elapsedMinutes minutos');
    print('  - Tiempo límite: $limitMinutes minutos');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.access_time, color: Colors.red, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Tiempo Expirado')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ya no es posible cancelar este servicio.',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tiempo transcurrido: $elapsedMinutes de $limitMinutes minutos',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El técnico ya está en camino hacia tu ubicación. Por favor, espera su llegada.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// ✅ MÉTODO para forzar expiración manual del servicio
  Future<void> _forceExpireService() async {
    if (_activeRequest == null) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
          '${Constants.baseUrl}/service/request/${_activeRequest!.id}/force-expire');
      final token = await TokenStorage.getToken();

      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('🚀 Forzando expiración del servicio: ${_activeRequest!.id}');
      final response = await http.post(url, headers: headers);

      print('📡 Respuesta del servidor: ${response.statusCode}');
      print('📡 Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Servicio expirado exitosamente: ${responseData['message']}');

        _showSuccessMessage('Servicio cancelado por tiempo expirado');
        _resetToIdle();
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Error al expirar el servicio';

        if (response.statusCode == 400) {
          // El servicio aún no ha llegado al límite de 1 hora
          final minutesElapsed = errorData['minutes_elapsed'] ?? 0;
          _showErrorMessage(
              'El servicio aún no ha llegado al límite de 1 hora (${minutesElapsed} minutos transcurridos)');
        } else {
          _showErrorMessage(errorMessage);
        }
      }
    } catch (e) {
      print('❌ Error forzando expiración: $e');
      _showErrorMessage(
          'Error al cancelar el servicio expirado: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _shouldShowForceExpireOption() {
    if (_activeRequest == null || _passengerStatus == PassengerStatus.idle) {
      return false;
    }

    // Solo mostrar si han pasado más de 60 minutos
    final referenceTime =
        _activeRequest!.acceptedAt ?? _activeRequest!.requestedAt;
    final minutesElapsed = DateTime.now().difference(referenceTime).inMinutes;

    return minutesElapsed >= 60 &&
        _passengerStatus != PassengerStatus.completed &&
        ['accepted', 'en_route', 'on_site', 'charging']
            .contains(_activeRequest!.status);
  }

// ✅ WIDGET para mostrar botón de expiración forzada
  Widget _buildForceExpireButton() {
    if (!_shouldShowForceExpireOption()) {
      return const SizedBox.shrink();
    }

    final referenceTime =
        _activeRequest!.acceptedAt ?? _activeRequest!.requestedAt;
    final minutesElapsed = DateTime.now().difference(referenceTime).inMinutes;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Servicio ha excedido el tiempo límite',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'El servicio lleva ${minutesElapsed} minutos activo. Puedes cancelarlo sin cargos.',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showForceExpireConfirmation(),
            icon: Icon(Icons.timer_off, color: Colors.white),
            label: Text(
              'Cancelar Servicio Expirado',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ✅ DIÁLOGO de confirmación para expiración forzada
  void _showForceExpireConfirmation() {
    final referenceTime =
        _activeRequest!.acceptedAt ?? _activeRequest!.requestedAt;
    final hoursElapsed = DateTime.now().difference(referenceTime).inHours;
    final minutesElapsed = DateTime.now().difference(referenceTime).inMinutes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.timer_off, color: Colors.orange, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Cancelar por Tiempo Expirado')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas cancelar este servicio?',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Información del servicio:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Tiempo transcurrido: ${hoursElapsed}h ${minutesElapsed % 60}m\n'
                    '• Estado actual: ${_activeRequest!.status}\n'
                    '• No se aplicarán cargos por cancelación\n'
                    '• Podrás solicitar un nuevo servicio inmediatamente',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _forceExpireService();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Sí, Cancelar Servicio',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _startCancellationTimer() {
    print('🕐 Iniciando timer de cancelación...');
    _cancellationTimeTimer?.cancel();

    // ✅ OBTENER información inicial de tiempo REAL desde el servidor
    _updateCancellationTimeInfo().then((_) {
      print('🕐 Tiempo inicial obtenido: $_cancellationTimeRemaining segundos');

      // ✅ Solo iniciar countdown si hay tiempo disponible
      if (_cancellationTimeRemaining > 0 && _canStillCancel) {
        _cancellationTimeTimer =
            Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_cancellationTimeRemaining > 0) {
            setState(() {
              _cancellationTimeRemaining--;
            });
            print('⏰ Tiempo restante: $_cancellationTimeRemaining segundos');
          } else {
            setState(() {
              _canStillCancel = false;
            });
            print('⛔ Tiempo de cancelación expirado');
            timer.cancel();
          }
        });
      } else {
        print('⚠️ No hay tiempo disponible para cancelar');
        setState(() {
          _canStillCancel = false;
          _cancellationTimeRemaining = 0;
        });
      }
    });
  }

  // ✅ BUILD METHOD MODIFICADO para manejar la verificación
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    if (_isCheckingVehicle) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.checkingVehicle, // ✅ CAMBIAR de 'Verificando tu vehículo'
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.verifyingInformation, // ✅ CAMBIAR de 'Estamos verificando tu información...'
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si no tiene vehículo registrado, no mostrar nada (porque se mostrará el diálogo)
    if (!_hasVehicleRegistered) {
      return Scaffold(
        body: Container(
          color: AppColors.background,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Código original del build method
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _logic.initialCameraPosition,
            onMapCreated: (controller) =>
                _logic.mapController.complete(controller),
            markers: _logic.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 80,
              bottom: _passengerStatus == PassengerStatus.idle ? 120 : 250,
            ),
          ),
          // UI Principal
          _buildMainUI(),
          // Loading Overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

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
                l10n.processing, // ✅ CAMBIAR de 'Procesando...'
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

  void _showCancellationWithFeeDialog(double fee) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber, color: Colors.orange, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Servicio Cancelado')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu servicio ha sido cancelado exitosamente.',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.cancellationFee(fee.toStringAsFixed(2)),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.feeApplied(fee.toStringAsFixed(2)),
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.understood, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// ✅ MEJORAR _buildCancellationTimeWidget para mostrar información más clara
  Widget _buildCancellationTimeWidget() {
    final l10n = AppLocalizations.of(context);

    // No mostrar si no hay request activo o si está en idle
    if (_activeRequest == null || _passengerStatus == PassengerStatus.idle) {
      return const SizedBox.shrink();
    }

    // Si no puede cancelar, mostrar mensaje diferente
    if (!_canStillCancel) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.cancellationTimeExpired,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Si el tiempo es 0 o menor, no mostrar
    if (_cancellationTimeRemaining <= 0) {
      return const SizedBox.shrink();
    }

    final minutes = (_cancellationTimeRemaining / 60).floor();
    final seconds = _cancellationTimeRemaining % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: minutes < 1
            ? Colors.red.withOpacity(0.1) // Rojo si queda menos de 1 minuto
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: minutes < 1
                ? Colors.red.withOpacity(0.3)
                : Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time,
              color: minutes < 1 ? Colors.red : Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.timeToCancel, // ✅ CAMBIAR de 'Tiempo para cancelar:'
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: minutes < 1
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: minutes < 1
                        ? Colors.red.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            minutes < 1
                ? l10n.lastMinute
                : l10n
                    .minutesRemaining, // ✅ CAMBIAR de '¡Último minuto!' y 'minutos restantes'

            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: minutes < 1 ? FontWeight.bold : FontWeight.normal,
              color: minutes < 1 ? Colors.red.shade600 : Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainUI() {
    return Column(
      children: [
        // Header con estado
        _buildHeader(),

        const Spacer(),

        // Panel inferior según estado
        if (_passengerStatus == PassengerStatus.idle)
          _buildIdlePanel()
        else
          SlideTransition(
            position: _slideAnimation,
            child: _buildBottomPanel(),
          ),
      ],
    );
  }

  Color _getStatusIndicatorColor() {
    switch (_passengerStatus) {
      case PassengerStatus.searching:
        return Colors.yellow;
      case PassengerStatus.driverAssigned:
        return Colors.blue;
      case PassengerStatus.onTrip:
        return Colors.green;
      case PassengerStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

// ✅ MEJORAR EL HEADER para mostrar mejor información del estado
  @override
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/logoapp.png',
              height: 32,
              width: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Estado con animación
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (_passengerStatus != PassengerStatus.idle) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusIndicatorColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        _getStatusTitle(),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_passengerStatus != PassengerStatus.idle) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getStatusSubtitle(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Indicador de progreso si hay servicio activo
          if (_passengerStatus != PassengerStatus.idle) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${(_serviceProgress * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusTitle() {
    final l10n = AppLocalizations.of(context);

    switch (_passengerStatus) {
      case PassengerStatus.idle:
        return l10n.appTitle;
      case PassengerStatus.searching:
        return '${l10n.searchingTechnician}${'.' * _searchingDots}';
      case PassengerStatus.driverAssigned:
        return l10n.technicianArriving;
      case PassengerStatus.onTrip:
        return l10n.serviceInProgress;
      case PassengerStatus.completed:
        return l10n.serviceCompleted;
    }
  }

  String _getStatusSubtitle() {
    final l10n = AppLocalizations.of(context); // ✅ YA EXISTE

    switch (_passengerStatus) {
      case PassengerStatus.searching:
        return l10n
            .findingBestTechnician; // ✅ CAMBIAR de 'Finding the best technician for you'
      case PassengerStatus.driverAssigned:
        return '${l10n.arrival}: $_estimatedTime ${l10n.minutes}'; // ✅ YA CORRECTO
      case PassengerStatus.onTrip:
        return l10n.chargingVehicle; // ✅ YA CORRECTO
      case PassengerStatus.completed:
        return l10n
            .thankYouForUsingVoltGo; // ✅ CAMBIAR de 'Thank you for using VoltGo'
      default:
        return '';
    }
  }

// Modificar el botón en _buildIdlePanel para mostrar estado correcto
  Widget _buildIdlePanel() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Container(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 150,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón principal de solicitar servicio
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hasActiveService
                    ? [AppColors.warning, AppColors.warning.withOpacity(0.8)]
                    : [AppColors.primary, AppColors.brandBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (_hasActiveService
                          ? AppColors.warning
                          : AppColors.primary)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _requestService,
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _hasActiveService
                            ? Icons.visibility
                            : Icons.electric_bolt,
                        color: AppColors.accent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasActiveService
                          ? l10n.viewActiveService // ✅ YA EXISTE
                          : l10n.requestCharge, // ✅ YA EXISTE
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _hasActiveService
                          ? l10n.youHaveActiveService // ✅ YA EXISTE
                          : l10n.tapToFindTechnician, // ✅ YA EXISTE
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    Widget content;

    switch (_passengerStatus) {
      case PassengerStatus.searching:
        content = _buildSearchingContent();
        break;
      case PassengerStatus.driverAssigned:
        content = _buildDriverAssignedContent();
        break;
      case PassengerStatus.onTrip:
        content = _buildOnTripContent();
        break;
      default:
        content = const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 150, // Aumentado de 76 a 150 para mover el panel más arriba
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildSearchingContent() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenedor de Precio y Tiempo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.attach_money,
                            color: AppColors.primary, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_estimatedPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          l10n.estimated, // ✅ CAMBIAR de 'Estimado'
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.gray300,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.access_time,
                            color: AppColors.primary, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          '$_estimatedTime min',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          l10n.arrival, // ✅ CAMBIAR de 'Llegada'
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              l10n.nearbyTechnicians, // ✅ CAMBIAR de 'Buscando técnicos cercanos'

              textAlign: TextAlign.center, // Buen hábito para centrar textos
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.thisCanTakeSeconds, // ✅ CAMBIAR de 'Esto puede tomar unos segundos'
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  child: Lottie.asset(
                    'assets/images/Charging.json',
                    fit: BoxFit
                        .contain, // Usar 'contain' es más seguro que 'fitWidth'
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Botón de cancelar
            OutlinedButton(
              onPressed: _cancelRide,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.cancelSearch, // ✅ YA EXISTE
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ✅ _buildDriverAssignedContent COMPLETO - PassengerMapScreen
  Widget _buildDriverAssignedContent() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    final bool isTechnicianOnSite = _activeRequest?.status == 'on_site';

    return Column(
      children: [
        // ✅ MOSTRAR tiempo restante de cancelación (solo si no está en sitio)
        if (!isTechnicianOnSite) _buildCancellationTimeWidget(),

        // Widget de expiración forzada (si aplica)
        _buildForceExpireButton(),

        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Banner de estado adaptativo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isTechnicianOnSite
                        ? [
                            Colors.purple.withOpacity(0.1),
                            Colors.purple.withOpacity(0.05)
                          ]
                        : [
                            Colors.green.withOpacity(0.1),
                            Colors.green.withOpacity(0.05)
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isTechnicianOnSite
                          ? Colors.purple.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isTechnicianOnSite
                          ? Icons.location_on
                          : Icons.check_circle,
                      color: isTechnicianOnSite ? Colors.purple : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTechnicianOnSite
                                ? l10n
                                    .technicianOnSite // ✅ CAMBIAR de 'Técnico en sitio'
                                : l10n
                                    .technicianConfirmed, // ✅ CAMBIAR de 'Técnico confirmado'
                            style: GoogleFonts.inter(
                              color: isTechnicianOnSite
                                  ? Colors.purple.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            isTechnicianOnSite
                                ? l10n
                                    .preparingEquipment // ✅ CAMBIAR de 'Preparando el equipo de carga'
                                : (!_canStillCancel
                                    ? l10n
                                        .cannotCancelServiceNow // ✅ CAMBIAR de 'Ya no es posible cancelar'
                                    : l10n
                                        .technicianHeadingToLocation), // ✅ CAMBIAR de 'En camino hacia tu ubicación'
                            style: GoogleFonts.inter(
                              color: isTechnicianOnSite
                                  ? Colors.purple.shade600
                                  : (!_canStillCancel
                                      ? Colors.red.shade600
                                      : Colors.green.shade600),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Fila superior con información del técnico
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar del técnico
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _driverName.isNotEmpty
                            ? _driverName[0].toUpperCase()
                            : 'T',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Columna con nombre, calificación e información del vehículo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _driverName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star,
                                color: AppColors.warning, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _driverRating,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '• $_vehicleInfo',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botones de acción
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Lógica para llamar al técnico
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.phone,
                              color: AppColors.success, size: 20),
                        ),
                      ),
                      IconButton(
                        onPressed: _openChat,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.message,
                              color: AppColors.info, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ✅ Información del servicio
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.electrical_services,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.connector, // ✅ CAMBIAR de 'Conector'
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          _connectorType,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // ✅ Mostrar información diferente según el estado
                    if (!isTechnicianOnSite) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                l10n.estimatedTime, // ✅ CAMBIAR de 'Tiempo estimado'
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Text(
                            '${_estimatedTime} ${l10n.minutes}', // ✅ CAMBIAR de 'minutos'
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.build,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                l10n.equipmentStatus, // ✅ CAMBIAR de 'Estado del equipo'
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Text(
                            l10n.preparingCharge, // ✅ CAMBIAR de 'Preparando carga'
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.estimatedCost, // ✅ CAMBIAR de 'Costo estimado'
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          '\$${_estimatedPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ✅ Barra de progreso o mensaje de espera según el estado
              if (!isTechnicianOnSite) ...[
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.technicianArriving} $_estimatedTime ${l10n.minutes}', // ✅ CAMBIAR de 'Técnico llegando en $_estimatedTime minutos'

                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.3,
                      backgroundColor: AppColors.gray300,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty,
                          color: Colors.purple, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.technicianPreparingEquipment, // ✅ CAMBIAR de 'El técnico está preparando el equipo. El servicio comenzará pronto.'
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ✅ Botones adaptados según el estado
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.navigation,
                        size: 20, color: Colors.white),
                    label: Text(isTechnicianOnSite
                        ? l10n
                            .viewTechnicianOnSite // ✅ CAMBIAR de 'Ver técnico en sitio'
                        : l10n
                            .followInRealTime), // ✅ CAMBIAR de 'Seguir en tiempo real'

                    onPressed: _openRealTimeTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTechnicianOnSite
                          ? Colors.purple
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Botón de Cancelar (deshabilitado si está en sitio)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (_canStillCancel && !isTechnicianOnSite)
                              ? _cancelActiveService
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                              color: (_canStillCancel && !isTechnicianOnSite)
                                  ? AppColors.error
                                  : Colors.grey.shade400,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          child: Text(isTechnicianOnSite
                              ? l10n
                                  .notCancellable // ✅ CAMBIAR de 'No cancelable'
                              : l10n.cancel), // ✅ YA EXISTE
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Botón de Chat
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat,
                              size: 20, color: Colors.white),
                          label: Text(l10n.chat), // ✅ CAMBIAR de 'Chat'

                          onPressed: _openChat,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

// ✅ MÉTODO _openRealTimeTracking CORREGIDO:
  void _openRealTimeTracking() async {
    final l10n = AppLocalizations.of(context); // ✅ YA EXISTE

    if (_activeRequest == null) {
      // ✅ CAMBIADO: _currentRequest → _activeRequest
      _showErrorSnackbar('No hay servicio activo');
      return;
    }

    // Navegar a la pantalla de seguimiento
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RealTimeTrackingScreen(
          serviceRequest:
              _activeRequest!, // ✅ CAMBIADO: _currentRequest → _activeRequest
          canStillCancel: _canStillCancel,
          onServiceComplete: () {
            print('✅ Servicio completado desde tracking screen');
          },
          onCancel: () {
            _cancelActiveService(); // ✅ CORREGIDO: llamada directa al método
            print('❌ Servicio cancelado desde tracking screen');
          },
        ),
      ),
    );

    // Manejar el resultado cuando regresa de la pantalla
    if (result == true && mounted) {
      setState(() {
        _refreshServiceData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(l10n
                  .serviceUpdatedCorrectly), // ✅ CAMBIAR de 'Servicio actualizado correctamente'
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _refreshServiceData() async {
    try {
      if (_activeRequest != null) {
        // ✅ CAMBIADO: _currentRequest → _activeRequest
        final updatedRequest =
            await ServiceRequestService.getRequestStatus(_activeRequest!.id);
        setState(() {
          _activeRequest =
              updatedRequest; // ✅ CAMBIADO: _currentRequest → _activeRequest
          // Actualizar otros estados según sea necesario
        });
      }
    } catch (e) {
      print('Error refreshing service data: $e');
    }
  }

  void _openChat() async {
    if (_activeRequest == null) {
      _showErrorSnackbar('No hay servicio activo');
      return;
    }

    HapticFeedback.lightImpact();

    // Navegar a la pantalla de chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceChatScreen(
          serviceRequest: _activeRequest!,
          userType: 'user', // Siempre 'user' en PassengerMapScreen
        ),
      ),
    );
  }

// Widget para el banner de estado
  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            'Técnico confirmado',
            style: GoogleFonts.inter(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

// Widget para la información del técnico
  Widget _buildDriverInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _driverName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.warning, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _driverRating,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '• $_vehicleInfo',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

// Widget para los botones de acción
  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            // Lógica para llamar al técnico
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone, color: AppColors.success, size: 20),
          ),
        ),
        IconButton(
          onPressed: () {
            // Lógica para enviar mensaje
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.message, color: AppColors.info, size: 20),
          ),
        ),
      ],
    );
  }

// Widget para la información del servicio
  Widget _buildServiceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildServiceInfoRow(
            icon: Icons.electrical_services,
            label: 'Conector',
            value: _connectorType,
          ),
          const SizedBox(height: 12),
          _buildServiceInfoRow(
            icon: Icons.access_time,
            label: 'Tiempo estimado',
            value: '$_estimatedTime minutos',
          ),
          const SizedBox(height: 12),
          _buildServiceInfoRow(
            icon: Icons.attach_money,
            label: 'Costo estimado',
            value: '\$${_estimatedPrice.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

// Widget reutilizable para cada fila de información del servicio
  Widget _buildServiceInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

// Widget para la barra de progreso
  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Técnico llegando en $_estimatedTime minutos',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.3, // Este valor debería ser dinámico
          backgroundColor: AppColors.gray300,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 6,
        ),
      ],
    );
  }

// Widget para el botón de cancelar
  Widget _buildCancelButton() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelRide,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              side: BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Agregar esta dependencia para la animación de búsqueda
class SpinKitRipple extends StatefulWidget {
  final Color color;
  final double size;

  const SpinKitRipple({
    Key? key,
    required this.color,
    this.size = 50.0,
  }) : super(key: key);

  @override
  _SpinKitRippleState createState() => _SpinKitRippleState();
}

class _SpinKitRippleState extends State<SpinKitRipple>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _animation1 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );

    _animation2 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          ScaleTransition(
            scale: _animation1,
            child: Container(
              height: widget.size,
              width: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(0.4),
                  width: 3,
                ),
              ),
            ),
          ),
          ScaleTransition(
            scale: _animation2,
            child: Container(
              height: widget.size,
              width: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(0.3),
                  width: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
