// ✅ PROVIDER PARA MANEJAR NOTIFICACIONES DE CHAT
// Archivo: lib/providers/ChatNotificationProvider.dart

import 'dart:async';
import 'package:Voltgo_User/data/services/ChatService.dart';
import 'package:flutter/foundation.dart';
 
class ChatNotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  Map<int, int> _unreadByService = {};
  bool _isLoading = false;
  Timer? _refreshTimer;

  // Getters
  int get unreadCount => _unreadCount;
  Map<int, int> get unreadByService => _unreadByService;
  bool get isLoading => _isLoading;

  ChatNotificationProvider() {
    // Cargar datos iniciales
    loadUnreadCount();
    // Configurar refresh automático cada 30 segundos
    _startPeriodicRefresh();
  }

  // ✅ INICIAR REFRESH AUTOMÁTICO
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      loadUnreadCount();
    });
  }

  // ✅ OBTENER CANTIDAD DE MENSAJES NO LEÍDOS
  Future<void> loadUnreadCount() async {
    if (_isLoading) return;
    
    _isLoading = true;
    if (kDebugMode) {
      notifyListeners(); // Solo notificar en debug para mostrar loading
    }

    try {
      final count = await ChatService.getUnreadMessagesCount();
      final byService = await ChatService.getUnreadMessagesByService();
      
      _unreadCount = count;
      _unreadByService = byService;
      
      print('📱 Mensajes no leídos cargados: $_unreadCount');
      print('📱 Por servicio: $_unreadByService');
    } catch (e) {
      print('❌ Error cargando mensajes no leídos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  int getUnreadCount(int serviceId) {
  return _unreadByService[serviceId] ?? 0;
}

  // ✅ INCREMENTAR CONTADOR (cuando llega notificación push)
  void incrementUnreadCount({int? serviceId}) {
    _unreadCount++;
    
    if (serviceId != null) {
      _unreadByService[serviceId] = (_unreadByService[serviceId] ?? 0) + 1;
    }
    
    notifyListeners();
    print('📱 Contador incrementado: $_unreadCount, servicio: $serviceId');
  }

  // ✅ MARCAR SERVICIO COMO LEÍDO
Future<void> markAsRead(int serviceId) async {
    try {
      // Marcar en el backend
      final success = await ChatService.markChatAsRead(serviceId);
      
      if (success && _unreadByService.containsKey(serviceId)) {
        final serviceUnread = _unreadByService[serviceId] ?? 0;
        _unreadCount = (_unreadCount - serviceUnread).clamp(0, double.infinity).toInt();
        _unreadByService.remove(serviceId);
        
        notifyListeners();
        print('📱 Servicio $serviceId marcado como leído');
      }
    } catch (e) {
      print('❌ Error marcando servicio como leído: $e');
    }
  }

  // ✅ DECREMENTAR CONTADOR
  void decrementUnreadCount({int? serviceId}) {
    if (_unreadCount > 0) {
      _unreadCount--;
    }
    
    if (serviceId != null && _unreadByService.containsKey(serviceId)) {
      final current = _unreadByService[serviceId] ?? 0;
      if (current > 1) {
        _unreadByService[serviceId] = current - 1;
      } else {
        _unreadByService.remove(serviceId);
      }
    }
    
    notifyListeners();
  }

  // ✅ RESET CONTADOR
  void resetUnreadCount() {
    _unreadCount = 0;
    _unreadByService.clear();
    notifyListeners();
    print('📱 Contador de mensajes reseteado');
  }

  // ✅ ACTUALIZAR DESDE NOTIFICACIÓN PUSH
  void updateFromPushNotification(Map<String, dynamic> data) {
    try {
      final serviceIdStr = data['service_request_id'];
      if (serviceIdStr != null) {
        final serviceId = int.tryParse(serviceIdStr.toString());
        if (serviceId != null) {
          incrementUnreadCount(serviceId: serviceId);
        }
      } else {
        incrementUnreadCount();
      }
    } catch (e) {
      print('❌ Error actualizando desde push notification: $e');
      incrementUnreadCount();
    }
  }

  // ✅ FORZAR REFRESH MANUAL
  Future<void> forceRefresh() async {
    await loadUnreadCount();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}