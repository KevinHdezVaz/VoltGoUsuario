// ✅ SERVICIO SIMPLE DE POLLING
// Archivo: lib/data/services/ChatPolling.dart
import 'dart:async';

import 'package:Voltgo_User/data/models/chat/ChatMessage.dart';
import 'package:Voltgo_User/data/services/ChatService.dart'; 
class ChatPolling {
  Timer? _timer;
  List<ChatMessage> _lastMessages = [];
  Function(List<ChatMessage>)? _onNewMessages;
  int? _serviceId;

  void startPolling(
      int serviceRequestId, Function(List<ChatMessage>) onNewMessages) {
    stopPolling();

    _serviceId = serviceRequestId;
    _onNewMessages = onNewMessages;

    // Cargar mensajes inmediatamente
    _checkMessages();

    // Polling cada 3 segundos
    _timer = Timer.periodic(Duration(seconds: 3), (_) => _checkMessages());
  }

  void _checkMessages() async {
    if (_serviceId == null || _onNewMessages == null) return;

    try {
      final messages = await ChatService.getChatHistory(_serviceId!);
      

      // Solo notificar si hay cambios
      if (messages.length != _lastMessages.length ||
          (messages.isNotEmpty &&
              _lastMessages.isNotEmpty &&
              messages.last.id != _lastMessages.last.id)) {
        _lastMessages = messages;
        _onNewMessages!(messages);
      }
    } catch (e) {
      print('Error en polling: $e');
    }
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _serviceId = null;
    _onNewMessages = null;
    _lastMessages.clear();
  }
}
