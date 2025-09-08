import 'dart:convert';
 import 'package:Voltgo_User/data/services/ServiceDetailsModel.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';
import 'package:http/http.dart' as http;

class ServiceDetailsService {
  static Future<ServiceDetailsModel?> fetchServiceDetails(int serviceRequestId) async {
    final url = Uri.parse('${Constants.baseUrl}/service/request/$serviceRequestId/details');
    final token = await TokenStorage.getToken();
    
    if (token == null) throw Exception('Token no encontrado');
    
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('Getting service details for request: $serviceRequestId');
      final response = await http.get(url, headers: headers);
      print('Get service details response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        // Si la respuesta tiene la estructura: { "success": true, "data": { ... } }
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return ServiceDetailsModel.fromJson(jsonData['data']);
        }
        
        // Si la respuesta es directamente el objeto
        return ServiceDetailsModel.fromJson(jsonData);
        
      } else if (response.statusCode == 404) {
        // No hay detalles para este servicio aún
        print('No service details found for request: $serviceRequestId');
        return null;
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error al obtener detalles del servicio'};
        throw Exception(
            errorData['message'] ?? 'Error al obtener detalles del servicio');
      }
    } catch (e) {
      print('Error in fetchServiceDetails: $e');
      rethrow;
    }
  }

  static Future<ServiceDetailsModel?> fetchServiceDetailsById(int serviceDetailsId) async {
    final url = Uri.parse('${Constants.baseUrl}/service/details/$serviceDetailsId');
    final token = await TokenStorage.getToken();
    
    if (token == null) throw Exception('Token no encontrado');
    
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('Getting service details by ID: $serviceDetailsId');
      final response = await http.get(url, headers: headers);
      print('Get service details by ID response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return ServiceDetailsModel.fromJson(jsonData['data']);
        }
        
        return ServiceDetailsModel.fromJson(jsonData);
        
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error al obtener detalles del servicio'};
        throw Exception(
            errorData['message'] ?? 'Error al obtener detalles del servicio');
      }
    } catch (e) {
      print('Error in fetchServiceDetailsById: $e');
      rethrow;
    }
  }

  // Método específico para notificaciones o casos especiales
  static Future<ServiceDetailsModel?> getServiceDetailsForNotification(int serviceRequestId) async {
    try {
      return await fetchServiceDetails(serviceRequestId);
    } catch (e) {
      print('Error obteniendo ServiceDetails para notificación: $e');
      return null;
    }
  }
}