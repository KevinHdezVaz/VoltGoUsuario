import 'dart:async';
import 'dart:convert';
import 'dart:io'; 
import 'package:Voltgo_User/data/services/ServiceChatScreen.dart';
import 'package:Voltgo_User/data/services/ServiceRequestService.dart';
import 'package:Voltgo_User/utils/ChatNotificationProvider.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; 

// Logging siguiendo tu patrón
class Log {
  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    final logMessage = '[ERROR] $tag: $message${error != null ? ' | Error: $error' : ''}${stackTrace != null ? '\nStackTrace: $stackTrace' : ''}';
    debugPrint(logMessage);
  }
  
  static void i(String tag, String message) {
    debugPrint('[INFO] $tag: $message');
  }
  
  static void d(String tag, String message) {
    debugPrint('[DEBUG] $tag: $message');
  }
}

// Eventos para comunicación entre widgets
class NewServiceRequestEvent {
  final int serviceRequestId;
  final String clientName;
  final Map<String, dynamic> additionalData;
  NewServiceRequestEvent(this.serviceRequestId, this.clientName, this.additionalData);
}

class ServiceCancelledEvent {
  final int serviceRequestId;
  final String reason;
  ServiceCancelledEvent(this.serviceRequestId, this.reason);
}

class ServiceStatusUpdateEvent {
  final int serviceRequestId;
  final String newStatus;
  final String? oldStatus;
  ServiceStatusUpdateEvent(this.serviceRequestId, this.newStatus, [this.oldStatus]);
}

class ChatMessageEvent {
  final int serviceRequestId;
  final String senderName;
  final String message;
  final Map<String, dynamic> additionalData;
  ChatMessageEvent(this.serviceRequestId, this.senderName, this.message, this.additionalData);
}

class OneSignalService {
  static const String _tag = 'OneSignalService';
  static const String _oneSignalAppId = "3708fbd6-1d48-48aa-94dc-3fa8cbdcdd16";
  static const _storage = FlutterSecureStorage();
  
  // EventBus para comunicación
  static final EventBus eventBus = EventBus();
  
  // Estado del servicio
  static bool _isInitialized = false;
  static String? _playerId;
  static String? _currentUserId;
  static String? _pushToken;
  static String? _deviceType;
  static BuildContext? _currentContext;

  /// Inicializar OneSignal
  static Future<void> initialize() async {
    if (_isInitialized) {
      Log.i(_tag, 'OneSignal already initialized');
      return;
    }

    try {
      Log.i(_tag, 'Starting OneSignal initialization');
      _deviceType = Platform.isIOS ? 'ios' : 'android';
      Log.d(_tag, 'Device type detected: $_deviceType');

      // Configurar OneSignal (nueva API v5.x)
      OneSignal.initialize(_oneSignalAppId);
      
      // Configurar logging
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Configurar handlers para notificaciones
      OneSignal.Notifications.addForegroundWillDisplayListener(_handleForegroundNotification);
      OneSignal.Notifications.addClickListener(_handleNotificationClicked);
      
      // Configurar handler para cambios de suscripción
      OneSignal.User.pushSubscription.addObserver(_handleSubscriptionChanged);

      // Obtener push token si está disponible
      try {
        _pushToken = OneSignal.User.pushSubscription.token;
        _playerId = OneSignal.User.pushSubscription.id;
        Log.d(_tag, 'Push token obtained: ${_pushToken != null ? "✓" : "✗"}');
        Log.d(_tag, 'Player ID obtained: ${_playerId != null ? "✓" : "✗"}');
      } catch (e) {
        Log.e(_tag, 'Error getting initial subscription state', e);
      }

      // Solicitar permisos
      final permissionGranted = await OneSignal.Notifications.requestPermission(true);
      Log.i(_tag, 'Push notification permission: ${permissionGranted ? "Granted" : "Denied"}');

      _isInitialized = true;
      Log.i(_tag, 'OneSignal initialized successfully');
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error initializing OneSignal', e, stackTrace);
      rethrow;
    }
  }

  /// Configurar contexto para acceder a Providers
  static void setContext(BuildContext context) {
    _currentContext = context;
    Log.d(_tag, 'Context set for OneSignal service');
  }

  /// Manejar cambios en suscripción
  static void _handleSubscriptionChanged(OSPushSubscriptionChangedState state) {
    Log.i(_tag, 'Subscription changed');
    Log.d(_tag, 'Previous subscription ID: ${state.previous?.id}');
    Log.d(_tag, 'Current subscription ID: ${state.current.id}');
    Log.d(_tag, 'Push token: ${state.current.token}');
    Log.d(_tag, 'Is opted in: ${state.current.optedIn}');

    _playerId = state.current.id;
    _pushToken = state.current.token;

    if (_playerId != null && _playerId!.isNotEmpty && _currentUserId != null) {
      Log.i(_tag, 'Player ID received, registering device immediately');
      _registerDeviceInBackend(_playerId!);
    } else {
      Log.d(_tag, 'Waiting for authenticated user or player ID not ready yet');
    }
  }

  /// Manejar notificaciones en primer plano
  static void _handleForegroundNotification(OSNotificationWillDisplayEvent event) {
    Log.i(_tag, 'Notification received in foreground');
    Log.d(_tag, 'Title: ${event.notification.title}');
    Log.d(_tag, 'Body: ${event.notification.body}');

    final data = event.notification.additionalData;
    if (data != null) {
      Log.d(_tag, 'Additional data: $data');
      _processNotificationData(data, isBackground: false);
    }

    // Mostrar la notificación en primer plano
    event.preventDefault();
    event.notification.display();
  }

  /// Manejar cuando el usuario toca una notificación
  static void _handleNotificationClicked(OSNotificationClickEvent event) {
    Log.i(_tag, 'Notification clicked by user');
    Log.d(_tag, 'Title: ${event.notification.title}');
    Log.d(_tag, 'Body: ${event.notification.body}');

    final data = event.notification.additionalData;
    if (data != null) {
      Log.d(_tag, 'Processing notification data: $data');
      _processNotificationData(data, isBackground: true);
    }
  }

  /// Procesar datos de notificación
  static void _processNotificationData(Map<String, dynamic> data, {required bool isBackground}) {
    final type = data['type'];
    Log.d(_tag, 'Processing notification type: $type, from background: $isBackground');

    try {
      switch (type) {
        case 'new_service_request':
          _handleNewServiceRequest(data, isBackground);
          break;
        case 'service_cancelled':
          _handleServiceCancelled(data, isBackground);
          break;
        case 'service_status_update':
          _handleServiceStatusUpdate(data, isBackground);
          break;
        case 'chat_message':
          _handleChatMessage(data, isBackground);
          break;
        default:
          Log.e(_tag, 'Unknown notification type: $type');
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error processing notification data', e, stackTrace);
    }
  }

  static void _handleNewServiceRequest(Map<String, dynamic> data, bool isBackground) {
    final serviceRequestId = _parseIntFromData(data['service_request_id']);
    final clientName = data['client_name'] ?? 'Cliente';
    Log.i(_tag, 'New service request: $clientName (ID: $serviceRequestId)');
    eventBus.fire(NewServiceRequestEvent(serviceRequestId, clientName, data));
  }

  /// Manejar cancelación de servicio
  static void _handleServiceCancelled(Map<String, dynamic> data, bool isBackground) {
    final serviceRequestId = _parseIntFromData(data['service_request_id']);
    final reason = data['reason'] ?? 'cancelled';
    Log.i(_tag, 'Service cancelled: ID $serviceRequestId, reason: $reason');
    eventBus.fire(ServiceCancelledEvent(serviceRequestId, reason));
  }

  /// Manejar actualización de estado
  static void _handleServiceStatusUpdate(Map<String, dynamic> data, bool isBackground) {
    final serviceRequestId = _parseIntFromData(data['service_request_id']);
    final newStatus = data['new_status'] ?? '';
    final oldStatus = data['old_status'];
    Log.i(_tag, 'Service status update: ID $serviceRequestId -> $newStatus');
    eventBus.fire(ServiceStatusUpdateEvent(serviceRequestId, newStatus, oldStatus));
  }

  // Manejar notificaciones de chat
  static void _handleChatMessage(Map<String, dynamic> data, bool isBackground) {
    final serviceRequestId = _parseIntFromData(data['service_request_id']);
    final senderName = data['sender_name'] ?? 'Usuario';
    final messageText = data['message'] ?? '';
    final userType = data['user_type'] ?? 'user';
    
    Log.i(_tag, 'Chat message received: $senderName in service $serviceRequestId');

    // Solo navegar si la notificación fue tocada (background)
    if (isBackground) {
      _navigateToChat(serviceRequestId, userType);
    }

    // Actualizar el provider de notificaciones de chat
    if (_currentContext != null) {
      try {
        final chatProvider = Provider.of<ChatNotificationProvider>(_currentContext!, listen: false);
        chatProvider.updateFromPushNotification(data);
        Log.d(_tag, 'Chat notification provider updated');
      } catch (e) {
        Log.e(_tag, 'Error updating chat provider', e);
      }
    }

    // Disparar evento para otros listeners
    eventBus.fire(ChatMessageEvent(serviceRequestId, senderName, messageText, data));
  }

  // Navegar a ServiceChatScreen
  static void _navigateToChat(int serviceRequestId, String userType) async {
    if (_currentContext == null) {
      Log.e(_tag, 'No context available for navigation');
      return;
    }

    try {
      Log.i(_tag, 'Navigating to chat for service $serviceRequestId');
      
      // Obtener datos del servicio
      final serviceRequest = await ServiceRequestService.getRequestStatus(serviceRequestId);
      
      if (serviceRequest != null) {
        Navigator.of(_currentContext!).push(
          MaterialPageRoute(
            builder: (context) => ServiceChatScreen(
              serviceRequest: serviceRequest,
              userType: userType,
            ),
          ),
        );
        
        Log.i(_tag, 'Successfully navigated to chat screen');
      } else {
        Log.e(_tag, 'Could not load service request data for navigation');
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error navigating to chat', e, stackTrace);
    }
  }

  /// Parsear entero de datos
  static int _parseIntFromData(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Registrar dispositivo en backend con todos los datos
  static Future<void> _registerDeviceInBackend(String playerId) async {
    Log.i(_tag, 'Registering device in backend');
    
    try {
      final token = await _getTokenWithValidation();
      final url = Uri.parse('${Constants.baseUrl}/onesignal/register-device');
      
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = jsonEncode({
        'player_id': playerId,
        'device_type': _deviceType ?? 'android',
        'device_token': _pushToken,
      });

      Log.d(_tag, 'Registering device - URL: $url');
      Log.d(_tag, 'Device data: player_id=$playerId, device_type=$_deviceType, push_token=$_pushToken');

      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      Log.i(_tag, 'Device registration response status: ${response.statusCode}');
      Log.d(_tag, 'Device registration response body: ${response.body}');

      if (response.statusCode == 200) {
        Log.i(_tag, 'Device registered successfully: $playerId');
      } else {
        Log.e(_tag, 'Device registration failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error registering device in backend', e, stackTrace);
    }
  }

  /// Actualizar estado de la app
  static Future<void> updateAppState(String state) async {
    Log.d(_tag, 'Updating app state to: $state');
    
    try {
      final token = await _getTokenWithValidation();
      final url = Uri.parse('${Constants.baseUrl}/technician/update-app-state');
      
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = jsonEncode({
        'app_state': state,
      });

      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Log.d(_tag, 'App state updated successfully: $state');
      } else {
        Log.e(_tag, 'App state update failed: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error updating app state', e, stackTrace);
    }
  }

  /// Configurar usuario autenticado
  static Future<void> setAuthenticatedUser(String userId, String authToken) async {
    Log.i(_tag, 'Setting authenticated user: $userId');
    _currentUserId = userId;
    
    try {
      await _storage.write(key: 'auth_token', value: authToken);
      
      // En OneSignal v5.x, configurar el usuario externo
      OneSignal.login(userId);
      
      // Obtener el ID de suscripción actual
      _playerId = OneSignal.User.pushSubscription.id;
      _pushToken = OneSignal.User.pushSubscription.token;
      
      if (_playerId != null && _playerId!.isNotEmpty) {
        Log.i(_tag, 'Player ID available, registering device');
        await _registerDeviceInBackend(_playerId!);
      } else {
        Log.d(_tag, 'No player ID available yet, will register when OneSignal connects');
        // Verificar después de un delay
        checkRegistrationAfterDelay();
      }
      
      Log.i(_tag, 'Authenticated user configured successfully');
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error setting authenticated user', e, stackTrace);
    }
  }

  /// Método para verificar el estado después de un delay
  static Future<void> checkRegistrationAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (_currentUserId != null && (_playerId == null || _playerId!.isEmpty)) {
      Log.d(_tag, 'Checking registration after delay...');
      try {
        _playerId = OneSignal.User.pushSubscription.id;
        _pushToken = OneSignal.User.pushSubscription.token;
        
        if (_playerId != null && _playerId!.isNotEmpty) {
          Log.i(_tag, 'Player ID obtained after delay: $_playerId');
          await _registerDeviceInBackend(_playerId!);
        } else {
          Log.e(_tag, 'Still no player ID after delay');
        }
      } catch (e, stackTrace) {
        Log.e(_tag, 'Error checking registration after delay', e, stackTrace);
      }
    }
  }

  /// Método público para forzar el registro del dispositivo
  static Future<void> forceRegisterDevice() async {
    Log.i(_tag, 'Force registering device...');
    if (_currentUserId == null) {
      Log.e(_tag, 'Cannot register device: no authenticated user');
      return;
    }

    try {
      _playerId = OneSignal.User.pushSubscription.id;
      _pushToken = OneSignal.User.pushSubscription.token;
      
      if (_playerId != null && _playerId!.isNotEmpty) {
        await _registerDeviceInBackend(_playerId!);
      } else {
        Log.e(_tag, 'No player ID available for registration');
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error in force register device', e, stackTrace);
    }
  }

  /// Limpiar usuario autenticado
  static Future<void> clearAuthenticatedUser() async {
    Log.i(_tag, 'Clearing authenticated user');
    _currentUserId = null;
    try {
      await _storage.delete(key: 'auth_token');
      OneSignal.logout();
      Log.i(_tag, 'User data cleared successfully');
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error clearing user data', e, stackTrace);
    }
  }

  /// Enviar notificación de prueba
  static Future<bool> sendTestNotification() async {
    Log.i(_tag, 'Sending test notification');
    try {
      final token = await _getTokenWithValidation();
      final url = Uri.parse('${Constants.baseUrl}/onesignal/test-notification');
      
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.post(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        Log.i(_tag, 'Test notification sent successfully');
        return true;
      } else {
        Log.e(_tag, 'Test notification failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error sending test notification', e, stackTrace);
      return false;
    }
  }

  /// Habilitar/deshabilitar notificaciones
  static Future<void> setNotificationsEnabled(bool enabled) async {
    Log.i(_tag, 'Setting notifications enabled: $enabled');
    try {
      if (enabled) {
        OneSignal.User.pushSubscription.optIn();
      } else {
        OneSignal.User.pushSubscription.optOut();
      }
      
      final token = await _getTokenWithValidation();
      final endpoint = enabled ? 'enable-notifications' : 'disable-notifications';
      final url = Uri.parse('${Constants.baseUrl}/onesignal/$endpoint');
      
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = enabled && _playerId != null
          ? jsonEncode({'player_id': _playerId})
          : null;

      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        Log.i(_tag, 'Notification settings updated successfully');
      } else {
        Log.e(_tag, 'Failed to update notification settings: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error setting notifications enabled', e, stackTrace);
    }
  }

  /// Obtener token con validación
  static Future<String> _getTokenWithValidation() async {
    Log.d(_tag, 'Fetching token from TokenStorage');
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      Log.e(_tag, 'Invalid or missing token');
      throw Exception('Authentication required: Invalid token');
    }
    Log.d(_tag, 'Token retrieved successfully');
    return token;
  }

  /// Getters
  static bool get isInitialized => _isInitialized;
  static String? get playerId => _playerId;
  static String? get currentUserId => _currentUserId;
  static String? get pushToken => _pushToken;
  static String? get deviceType => _deviceType;

  /// Cleanup
  static Future<void> dispose() async {
    Log.i(_tag, 'Disposing OneSignalService');
    _isInitialized = false;
    _playerId = null;
    _currentUserId = null;
    _pushToken = null;
    _deviceType = null;
    _currentContext = null;
  }
}