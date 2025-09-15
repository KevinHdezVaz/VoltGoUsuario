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
  /// Obtiene la lista de planes/precios activos desde el backend.
  static Future<List<StripePlan>> listPlans() async {
    final url = Uri.parse('${Constants.baseUrl}/stripe/plans');
    // Nota: Aunque el endpoint sea público, es buena práctica enviar el token si se tiene.
    // Si tu endpoint es 100% público, puedes omitir la parte del token.
    final token = await TokenStorage.getToken(); 

    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      print('Getting Stripe plans...');
      final response = await http.get(url, headers: headers);
      print('Get Stripe plans response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // La función helper decodifica la respuesta JSON en una lista de objetos StripePlan
        return stripePlanFromJson(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener los planes de Stripe');
      }
    } catch (e) {
      print('Error in listPlans: $e');
      rethrow; // Re-lanza la excepción para que la UI pueda manejarla
    }
  }

  /// Crea una intención de pago (Payment Intent) en el backend.
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