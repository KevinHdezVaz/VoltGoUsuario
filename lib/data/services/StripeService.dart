// data/services/stripe_service.dart

import 'dart:convert';
import 'package:Voltgo_User/data/models/StripePlan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
 import 'package:Voltgo_User/utils/TokenStorage.dart'; // Asegúrate que la ruta sea correcta
import 'package:Voltgo_User/utils/constants.dart'; // Asegúrate que la ruta sea correcta

class StripeService {




 static Future<bool> processPayment({
    required int serviceRequestId,
    required double amount,
  }) async {
    try {
      // 1. Crear Payment Intent en el backend
      print('🔄 Creando Payment Intent...');
      final paymentData = await createPaymentIntent(
        serviceRequestId: serviceRequestId,
      );
      
      final clientSecret = paymentData['clientSecret'] as String;
      final paymentIntentId = paymentData['paymentIntentId'] as String;
      
      // 2. Confirmar el pago con la hoja de pago nativa
      print('💳 Mostrando hoja de pago...');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'VoltGo',
          style: ThemeMode.system,
          billingDetails: const BillingDetails(
            name: 'Usuario VoltGo', // Puedes personalizarlo
          ),
        ),
      );

      // 3. Presentar la hoja de pago
      await Stripe.instance.presentPaymentSheet();
      
      print('✅ Pago procesado exitosamente: $paymentIntentId');
      return true;
      
    } on StripeException catch (e) {
      print('❌ Error de Stripe: ${e.error.localizedMessage}');
      
      // Manejar diferentes tipos de errores
      switch (e.error.code) {
        case FailureCode.Canceled:
          throw Exception('Pago cancelado por el usuario');
        case FailureCode.Failed:
          throw Exception('Error al procesar el pago: ${e.error.localizedMessage}');
        default:
          throw Exception('Error inesperado: ${e.error.localizedMessage}');
      }
    } catch (e) {
      print('❌ Error general: $e');
      throw Exception('Error al procesar el pago: $e');
    }
  }


// data/services/stripe_service.dart

static Future<bool> purchaseSubscription({required String priceId}) async {
  try {
    print('🔄 Iniciando compra del plan: $priceId');
    
    // 1. Crear suscripción en el backend Y ESPERAR la respuesta
    final subscriptionData = await _createSubscription(priceId: priceId);
    print('✅ Suscripción creada en backend');
    
    final clientSecret = subscriptionData['clientSecret'] as String;
    print('🔑 Client secret obtenido: ${clientSecret.substring(0, 20)}...');
    
    // 2. Inicializar Payment Sheet Y ESPERAR a que termine
    // ✅ ASEGÚRATE DE QUE ESTE 'await' ESTÉ AQUÍ
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'VoltGo',
        style: ThemeMode.system,
      ),
    );
    print('✅ Payment Sheet inicializado correctamente');

    // 3. Presentar Payment Sheet Y ESPERAR la acción del usuario
    await Stripe.instance.presentPaymentSheet();
    print('✅ Pago en la app completado. Esperando confirmación del servidor...');
    
    // 4. (Opcional, pero recomendado) Lógica de polling para verificar en el backend
    bool isSubscriptionActive = await _pollForActiveSubscription();

    if (isSubscriptionActive) {
      print('🎉 ¡Suscripción confirmada y activa en el servidor!');
      return true;
    } else {
      throw Exception('El servidor no confirmó la activación de la suscripción a tiempo.');
    }
    
  } on StripeException catch (e) {
    print('❌ Error de Stripe: ${e.error.code} - ${e.error.localizedMessage}');
    rethrow; // Re-lanza el error para que la UI lo pueda mostrar
  } catch (e) {
    print('❌ Error general en purchaseSubscription: $e');
    rethrow;
  }
}
/// Función auxiliar para hacer polling
static Future<bool> _pollForActiveSubscription({
  int maxAttempts = 10, // Intentar por 20 segundos máximo (10 intentos * 2 segundos)
  Duration delay = const Duration(seconds: 2),
}) async {
  for (int i = 0; i < maxAttempts; i++) {
    print('🔄 Intento de verificación #${i + 1}...');
    final url = Uri.parse('${Constants.baseUrl}/user/subscription/current');
    final token = await TokenStorage.getToken();
    final headers = {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
    
    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Asume que tu respuesta tiene una clave 'subscription' que no es nula si está activa
      if (data['subscription'] != null) {
        return true; // ¡Éxito! La suscripción está activa.
      }
    }
    
    // Esperar antes del siguiente intento
    await Future.delayed(delay);
  }
  
  return false; // Se agotaron los intentos
}



  static Future<Map<String, dynamic>> _createSubscription({required String priceId}) async {
    final url = Uri.parse('${Constants.baseUrl}/stripe/create-subscription');
    final token = await TokenStorage.getToken();
    
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({'price_id': priceId});

    final response = await http.post(url, headers: headers, body: body);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Error al crear suscripción');
    }
  }

/// Alternativa: Usar Payment Element personalizado (más control)
  static Future<bool> processPaymentCustom({
    required int serviceRequestId,
    required BuildContext context,
  }) async {
    try {
      // Crear Payment Intent
      final paymentData = await createPaymentIntent(
        serviceRequestId: serviceRequestId,
      );
      
      final clientSecret = paymentData['clientSecret'] as String;
      
      // Confirmar pago con tarjeta
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        
        // --- AQUÍ ESTÁ LA CORRECCIÓN ---
        // Antes tenías: data: PaymentMethodData(...)
        // Ahora lo envolvemos en PaymentMethodParams.card
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: 'Usuario VoltGo',
              // Aquí puedes añadir más detalles si los tienes, como el email
              // email: 'usuario@voltgo.com', 
            ),
          ),
        ),
        // --- FIN DE LA CORRECCIÓN ---
        
      );
      
      return true;
    } catch (e) {
      print('Error en pago personalizado: $e');
      rethrow;
    }
  }

// En stripe_service.dart - versión temporal para debugging

static Future<List<StripePlan>> listPlans() async {
  final url = Uri.parse('${Constants.baseUrl}/stripe/plans');
  final token = await TokenStorage.getToken(); 

  final headers = {
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  try {
    print('🔄 Getting Stripe plans...');
    final response = await http.get(url, headers: headers);
    print('📡 Response status: ${response.statusCode}');
    
    // ✅ MOSTRAR RESPUESTA COMPLETA PARA DEBUGGING
    print('📋 Raw response body:');
    print(response.body);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      
      // ✅ MOSTRAR ESTRUCTURA DE LA RESPUESTA
      print('📊 Response structure: ${jsonData.runtimeType}');
      if (jsonData is Map) {
        print('📊 Map keys: ${jsonData.keys.toList()}');
      }

      // Verificar si hay debug_info
      if (jsonData is Map && jsonData['debug_info'] != null) {
        print('🔍 DEBUG INFO FROM BACKEND:');
        print('   Total products: ${jsonData['debug_info']['total_stripe_products']}');
        print('   All product names: ${jsonData['debug_info']['all_product_names']}');
        print('   Filtered count: ${jsonData['debug_info']['filtered_count']}');
      }
      
      List<dynamic> plansArray;
      if (jsonData is List) {
        plansArray = jsonData;
      } else if (jsonData is Map && jsonData['plans'] != null) {
        plansArray = jsonData['plans'];
      } else if (jsonData is Map && jsonData['data'] != null) {
        plansArray = jsonData['data'];
      } else {
        throw Exception('Formato de respuesta no reconocido: ${jsonData.runtimeType}');
      }

      print('📦 Plans array length: ${plansArray.length}');

      final List<StripePlan> plans = [];
      
      for (var planData in plansArray) {
        try {
          print('🔧 Processing plan: ${planData['product_name']}');
          final plan = StripePlan.fromJson(planData as Map<String, dynamic>);
          plans.add(plan);
          print('✅ Plan added: ${plan.productName} - \$${plan.amount}');
        } catch (e) {
          print('❌ Error parsing plan: $planData, Error: $e');
        }
      }

      print('🎉 Successfully parsed ${plans.length} plans');
      print('📋 Plan names: ${plans.map((p) => p.productName).join(", ")}');
      
      return plans;

    } else {
      print('❌ Error response: ${response.statusCode}');
      print('❌ Error body: ${response.body}');
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Error al obtener los planes');
    }
  } catch (e) {
    print('💥 Error in listPlans: $e');
    rethrow;
  }
}
 
  /// Devuelve un mapa que contiene el 'clientSecret' necesario para el SDK de Stripe en Flutter.
  static Future<Map<String, dynamic>> createPaymentIntent({required int serviceRequestId}) async {
    final url = Uri.parse('${Constants.baseUrl}/payments/create-intent');
    final token = await TokenStorage.getToken();

    if (token == null) throw Exception('Token no encontrado. Se requiere autenticación.');

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8', // Importante para peticiones POST
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'service_request_id': serviceRequestId,
    });

    try {
      print('Creating Payment Intent for service request: $serviceRequestId');
      final response = await http.post(url, headers: headers, body: body);
      print('Create Payment Intent response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // La respuesta del backend es un JSON como: {"clientSecret": "pi_...", "paymentIntentId": "pi_..."}
        return jsonDecode(response.body);
      } else {
        // Manejo de errores específicos del backend
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear la intención de pago');
      }
    } catch (e) {
      print('Error in createPaymentIntent: $e');
      rethrow;
    }
  }
}