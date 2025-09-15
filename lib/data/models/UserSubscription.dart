// data/models/user_subscription.dart
class UserSubscription {
  final String? subscriptionId;
  final String? planType; // 'monthly' o 'one_time'
  final String? planName;
  final bool isActive;
  final DateTime? expiresAt;
  final int? remainingServices; // Para planes one-time
  
  UserSubscription({
    this.subscriptionId,
    this.planType,
    this.planName,
    required this.isActive,
    this.expiresAt,
    this.remainingServices,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      subscriptionId: json['subscription_id'],
      planType: json['plan_type'],
      planName: json['plan_name'],
      isActive: json['is_active'] ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      remainingServices: json['remaining_services'],
    );
  }
}