// ✅ SERVICIO DE CHAT COMPLETO CON NOTIFICACIONES
// Archivo: lib/data/services/ChatService.dart

import 'dart:convert';
import 'package:Voltgo_User/data/models/chat/ChatMessage.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';
import 'package:http/http.dart' as http; 

class ChatService {
  static const String _tag = 'ChatService';

  // ✅ OBTENER HISTORIAL DE MENSAJES
  static Future<List<ChatMessage>> getChatHistory(int serviceRequestId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token de autenticación no encontrado');
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/chat/service/$serviceRequestId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('$_tag: Chat history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'] ?? [];
        
        return messagesJson
            .map((json) => ChatMessage.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado - token inválido');
      } else if (response.statusCode == 403) {
        throw Exception('Sin permisos para acceder a este chat');
      } else if (response.statusCode == 404) {
        throw Exception('Servicio no encontrado');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('$_tag: Error en getChatHistory: $e');
      rethrow;
    }
  }

  // ✅ ENVIAR MENSAJE
  static Future<ChatMessage> sendMessage({
    required int serviceRequestId,
    required String message,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token de autenticación no encontrado');
      }

      if (message.trim().isEmpty) {
        throw Exception('El mensaje no puede estar vacío');
      }

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/chat/service/$serviceRequestId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': message.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      print('$_tag: Send message response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChatMessage.fromJson(data['message']);
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado - token inválido');
      } else if (response.statusCode == 403) {
        throw Exception('Sin permisos para enviar mensajes en este chat');
      } else if (response.statusCode == 404) {
        throw Exception('Servicio no encontrado');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('$_tag: Error en sendMessage: $e');
      rethrow;
    }
  }

  // ✅ OBTENER CONTADOR DE MENSAJES NO LEÍDOS
  static Future<int> getUnreadMessagesCount() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        return 0; // Retornar 0 en lugar de error para el contador
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/chat/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      } else {
        print('$_tag: Error obteniendo contador: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('$_tag: Error en getUnreadMessagesCount: $e');
      return 0;
    }
  }

  // ✅ OBTENER MENSAJES NO LEÍDOS POR SERVICIO
  static Future<Map<int, int>> getUnreadMessagesByService() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        return {};
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/chat/unread-by-service'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> unreadByService = data['unread_by_service'] ?? {};
        
        // Convertir a Map<int, int>
        return unreadByService.map((key, value) => 
          MapEntry(int.parse(key), value as int)
        );
      } else {
        print('$_tag: Error obteniendo no leídos por servicio: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('$_tag: Error en getUnreadMessagesByService: $e');
      return {};
    }
  }

  // ✅ MARCAR CHAT COMO LEÍDO
  static Future<bool> markChatAsRead(int serviceRequestId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/chat/service/$serviceRequestId/mark-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      } else {
        print('$_tag: Error marcando como leído: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('$_tag: Error en markChatAsRead: $e');
      return false;
    }
  }

  // ✅ OBTENER HISTORIAL DE CHATS
  static Future<List<ChatHistory>> getUserChatHistory() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token de autenticación no encontrado');
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/chat/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> historyJson = data['chat_history'] ?? [];
        
        return historyJson
            .map((json) => ChatHistory.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado - token inválido');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('$_tag: Error en getUserChatHistory: $e');
      rethrow;
    }
  }

  // ✅ OBTENER ESTADÍSTICAS DEL CHAT
  static Future<Map<String, dynamic>> getChatStats(int serviceRequestId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token de autenticación no encontrado');
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/chat/service/$serviceRequestId/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('$_tag: Error obteniendo estadísticas: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('$_tag: Error en getChatStats: $e');
      return {};
    }
  }
}

// ✅ MODELO PARA HISTORIAL DE CHAT
class ChatHistory {
  final int serviceId;
  final Map<String, dynamic>? otherParticipant;
  final Map<String, dynamic>? lastMessage;
  final String serviceDate;
  final int unreadCount;
  final String serviceStatus;

  ChatHistory({
    required this.serviceId,
    this.otherParticipant,
    this.lastMessage,
    required this.serviceDate,
    required this.unreadCount,
    required this.serviceStatus,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      serviceId: json['service_id'],
      otherParticipant: json['other_participant'],
      lastMessage: json['last_message'],
      serviceDate: json['service_date'],
      unreadCount: json['unread_count'] ?? 0,
      serviceStatus: json['service_status'] ?? 'unknown',
    );
  }

  String get otherParticipantName => otherParticipant?['name'] ?? 'Usuario';
  
  String get lastMessageText => lastMessage?['message'] ?? '';
  
  String get lastMessageTime => lastMessage?['sent_at'] ?? '';
  
  bool get hasUnreadMessages => unreadCount > 0;
}