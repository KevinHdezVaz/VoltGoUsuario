// data/services/subscription_service.dart
import 'dart:convert';

import 'package:Voltgo_User/data/models/UserSubscription.dart';
import 'package:Voltgo_User/data/services/StripeService.dart';
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
      
      if (data['has_subscription']) {
        return UserSubscription.fromJson(data['subscription']);
      }
      return null;
    } else {
      throw Exception('Error obteniendo suscripción');
    }
  } catch (e) {
    print('Error getting current subscription: $e');
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

