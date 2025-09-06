import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _tokenKey = 'auth_token';
  
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('🔑 Token guardado: ${token.substring(0, 20)}...');
      
      // Verificar inmediatamente que se guardó
      final savedToken = prefs.getString(_tokenKey);
      print('🔍 Verificación inmediata: ${savedToken != null ? "✅ Guardado" : "❌ No guardado"}');
    } catch (e) {
      print('❌ Error guardando token: $e');
      throw Exception('Error al guardar el token: $e');
    }
  }
  
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
  
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print('🔑 Obteniendo token: ${token != null ? "✅ Encontrado (${token.substring(0, 20)}...)" : "❌ No encontrado"}');
      return token;
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      throw Exception('Error al leer el token: $e');
    }
  }
  
  static Future<bool> isTokenValid() async {
  try {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    
    // Validación básica de formato JWT (opcional)
    final parts = token.split('.');
    if (parts.length != 3) {
      print('🚫 Token con formato inválido');
      await deleteToken();
      return false;
    }
    
    return true;
  } catch (e) {
    print('❌ Error validando token: $e');
    return false;
  }
}

  static Future<bool> hasToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final hasValidToken = token != null && token.isNotEmpty;
      
      print('🔍 hasToken(): $hasValidToken, valor actual: ${token?.substring(0, 20) ?? "null"}');
      
      return hasValidToken;
    } catch (e) {
      print('❌ Error verificando token: $e');
      throw Exception('Error al verificar el token: $e');
    }
  }
  
  static Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      print('🗑️ Token eliminado');
    } catch (e) {
      print('❌ Error eliminando token: $e');
      throw Exception('Error al eliminar el token: $e');
    }
  }
}