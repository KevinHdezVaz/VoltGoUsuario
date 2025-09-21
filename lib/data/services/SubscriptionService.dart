  // data/services/subscription_service.dart
  import 'dart:convert';

  import 'package:Voltgo_User/data/models/UserSubscription.dart';
  import 'package:Voltgo_User/utils/TokenStorage.dart';
  import 'package:Voltgo_User/utils/constants.dart';
  import 'package:http/http.dart' as http;

  class SubscriptionService {
  
  
 static Future<UserSubscription?> getCurrentSubscription() async {
  try {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final url = Uri.parse('${Constants.baseUrl}/user/subscription/current');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // ✅ AGREGAR DEBUG AQUÍ
      print('📊 Full API response: $data');
      print('📊 has_subscription: ${data['has_subscription']}');
      if (data['subscription'] != null) {
        print('📊 Raw subscription data: ${data['subscription']}');
        print('📊 remaining_services type: ${data['subscription']['remaining_services'].runtimeType}');
        print('📊 remaining_services value: ${data['subscription']['remaining_services']}');
      }
      
      if (data['has_subscription']) {
        try {
          return UserSubscription.fromJson(data['subscription']);
        } catch (parseError) {
          print('❌ Error parsing subscription: $parseError');
          print('📊 Raw subscription data that failed: ${data['subscription']}');
          rethrow;
        }
      }
      return null;
    } else {
      print('❌ API Error - Status: ${response.statusCode}');
      print('❌ API Error - Body: ${response.body}');
      throw Exception('Error obteniendo suscripción');
    }
  } catch (e) {
    print('Error getting current subscription: $e');
    throw e;
  }
}




  static Future<List<UserSubscription>> getSubscriptionHistory() async {
      try {
        final token = await TokenStorage.getToken();
        if (token == null) throw Exception('Token no encontrado');

        // Apunta al nuevo endpoint que creamos en Laravel
        final url = Uri.parse('${Constants.baseUrl}/user/subscription/history'); 
        final headers = {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        };

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Convierte la lista de JSONs en una lista de objetos UserSubscription
          final List<dynamic> historyList = data['history'];
          return historyList.map((item) => UserSubscription.fromJson(item)).toList();

        } else {
          throw Exception('Error obteniendo el historial de suscripciones');
        }
      } catch (e) {
        print('Error getting subscription history: $e');
        throw e;
      }
    }




  // En StripeService
  static Future<Map<String, dynamic>> purchaseSubscription({required String priceId}) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final url = Uri.parse('${Constants.baseUrl}/subscription/create');
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({'price_id': priceId});
      
      print('🚀 Creando suscripción...');
      final response = await http.post(url, headers: headers, body: body);
      
      print('📡 Respuesta: ${response.statusCode}');
      print('📋 Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // ✅ Devolver Map completo
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Error creando suscripción');
      }
      
    } catch (e) {
      print('❌ Error en purchaseSubscription: $e');
      rethrow;
    }
  } 

  static Future<Map<String, dynamic>> purchasePlan(String priceId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('No token found');

      print('🔄 Purchasing plan: $priceId');

      final url = Uri.parse('${Constants.baseUrl}/stripe/create-subscription');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'price_id': priceId}),
      );

      print('💳 Purchase plan response: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Validar que tenemos los campos necesarios
        if (data['success'] == true && data['clientSecret'] != null) {
          return {
            'success': true,
            'clientSecret': data['clientSecret'] as String,
            'planType': data['planType'] as String? ?? 'unknown',
            'requiresPayment': data['requiresPayment'] as bool? ?? true,
            'subscriptionId': data['subscriptionId'] as String?,
            'paymentIntentId': data['paymentIntentId'] as String?,
          };
        } else {
          throw Exception('Invalid response from server: missing clientSecret');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error desconocido del servidor');
      }
    } catch (e) {
      print('❌ Error in purchasePlan: $e');
      throw Exception('Error al comprar plan: $e');
    }
  }

  }

