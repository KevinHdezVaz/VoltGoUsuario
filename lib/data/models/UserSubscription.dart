// data/models/user_subscription.dart

class UserSubscription {
  // --- CAMPOS ORIGINALES ---
  final String? subscriptionId; // Se mantiene por si lo usas en otro lado
  final String? planType;
  final String? planName;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt; // Se mantiene, pero la fecha de compra es 'purchasedAt'
  final int? remainingServices;
  final int? totalServices;
  final int? servicesUsedThisMonth;

  // --- NUEVOS CAMPOS AÑADIDOS DE LA API ---
  final int id; // El ID numérico único de la base de datos
  final double amount; // El costo del plan
  final String currency; // La moneda (ej. 'USD')
  final DateTime purchasedAt; // La fecha real de la compra
  final String? planDescription; // Descripción del plan

  UserSubscription({
    // Originales
    this.subscriptionId,
    this.planType,
    this.planName,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
    this.remainingServices,
    this.totalServices,
    this.servicesUsedThisMonth,
    // Nuevos
    required this.id,
    required this.amount,
    required this.currency,
    required this.purchasedAt,
    this.planDescription,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    // Helper para parsear fechas de forma segura y evitar que la app crashee
    DateTime? _safeParseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print('Error parsing date: $dateString');
        return null;
      }
    }

    return UserSubscription(
      // Mapeo de campos originales
      subscriptionId: json['stripe_subscription_id'], // El 'subscriptionId' suele ser el de Stripe
      planType: json['plan_type'],
      planName: json['plan_name'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      expiresAt: _safeParseDate(json['expires_at']),
      createdAt: _safeParseDate(json['created_at']) ?? DateTime.now(),
      remainingServices: json['remaining_services'] as int?,
      totalServices: json['total_services'] as int?,
      servicesUsedThisMonth: json['services_used_this_month'] as int? ?? 0,

      // Mapeo de nuevos campos
      id: json['id'] as int,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      currency: json['currency'] ?? 'USD',
      // La API envía 'purchased_at'. Es la fecha más importante para el historial.
      purchasedAt: _safeParseDate(json['purchased_at']) ?? _safeParseDate(json['created_at']) ?? DateTime.now(),
      planDescription: json['plan_description'],
    );
  }
}