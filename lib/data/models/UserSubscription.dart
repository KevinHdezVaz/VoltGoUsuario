// data/models/user_subscription.dart
class UserSubscription {
  final String? subscriptionId;
  final String? planType; // 'monthly' o 'one_time'
  final String? planName;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final int? remainingServices; // Para planes one-time
  final int? totalServices; // Total de servicios del plan (para one-time)
  final int? servicesUsedThisMonth; // Para planes mensuales

  UserSubscription({
    this.subscriptionId,
    this.planType,
    this.planName,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
    this.remainingServices,
    this.totalServices,
    this.servicesUsedThisMonth,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      subscriptionId: json['subscription_id'],
      planType: json['plan_type'],
      planName: json['plan_name'],
      isActive: json['is_active'] ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      remainingServices: json['remaining_services'],
      totalServices: json['total_services'],
      servicesUsedThisMonth: json['services_used_this_month'] ?? 0,
    );
  }
}