import 'dart:convert';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';
import 'package:http/http.dart' as http; 

class RatingService {
  /// Enviar calificación para un servicio
  static Future<bool> submitRating(
    int serviceRequestId, 
    int rating, 
    String? comment
  ) async {
    final url = Uri.parse('${Constants.baseUrl}/service/request/$serviceRequestId/rating');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return false;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'rating': rating,
      'comment': comment,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("✅ Calificación enviada exitosamente");
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("❌ Error al enviar calificación: ${error['message']}");
        return false;
      }
    } catch (e) {
      print("❌ Error en submitRating: $e");
      return false;
    }
  }

  /// Verificar si se puede calificar un servicio
  static Future<Map<String, dynamic>?> canRateService(int serviceRequestId) async {
    final url = Uri.parse('${Constants.baseUrl}/service/request/$serviceRequestId/can-rate');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Verificación de rating obtenida");
        return data;
      } else {
        print("❌ Error verificando rating: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error en canRateService: $e");
      return null;
    }
  }

  /// Obtener calificación de un servicio específico
  static Future<Map<String, dynamic>?> getRating(int serviceRequestId) async {
    final url = Uri.parse('${Constants.baseUrl}/service/request/$serviceRequestId/rating');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Rating del servicio obtenido");
        return data;
      } else {
        print("❌ Error obteniendo rating: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error en getRating: $e");
      return null;
    }
  }

  /// Obtener calificaciones de un técnico
  static Future<Map<String, dynamic>?> getTechnicianRatings(
    int technicianId, {
    int page = 1,
    int perPage = 10
  }) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    final url = Uri.parse('${Constants.baseUrl}/technician/$technicianId/ratings')
        .replace(queryParameters: queryParams);

    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Ratings del técnico obtenidos");
        return data;
      } else {
        print("❌ Error obteniendo ratings del técnico: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error en getTechnicianRatings: $e");
      return null;
    }
  }

  /// Obtener calificaciones del usuario
  static Future<List<dynamic>> getUserRatings({int page = 1}) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': '20',
    };

    final url = Uri.parse('${Constants.baseUrl}/user/ratings')
        .replace(queryParameters: queryParams);

    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return [];
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Ratings del usuario obtenidos");
        return data['data'] ?? [];
      } else {
        print("❌ Error obteniendo ratings del usuario: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error en getUserRatings: $e");
      return [];
    }
  }

  /// Eliminar una calificación
  static Future<bool> deleteRating(int ratingId) async {
    final url = Uri.parse('${Constants.baseUrl}/rating/$ratingId');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return false;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        print("✅ Calificación eliminada exitosamente");
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("❌ Error al eliminar calificación: ${error['message']}");
        return false;
      }
    } catch (e) {
      print("❌ Error en deleteRating: $e");
      return false;
    }
  }

  /// Obtener resumen de calificaciones
  static Future<Map<String, dynamic>?> getRatingSummary() async {
    final url = Uri.parse('${Constants.baseUrl}/ratings/summary');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Resumen de ratings obtenido");
        return data;
      } else {
        print("❌ Error obteniendo resumen: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error en getRatingSummary: $e");
      return null;
    }
  }
}