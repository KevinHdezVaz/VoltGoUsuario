// Archivo: lib/data/models/User/ServiceDetailsModel.dart

class ServiceDetailsModel {
  final int id;
  final int serviceRequestId;
  final String? vehiclePhotoUrl;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final int? initialBatteryLevel;
  final int? chargeTimeMinutes;
  final String? serviceNotes;
  final DateTime? serviceStartedAt;
  final DateTime? serviceCompletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool serviceStarted;
  final DateTime? serviceStartTime;
  final List<String>? photosTaken;

  ServiceDetailsModel({
    required this.id,
    required this.serviceRequestId,
    this.vehiclePhotoUrl,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.initialBatteryLevel,
    this.chargeTimeMinutes,
    this.serviceNotes,
    this.serviceStartedAt,
    this.serviceCompletedAt,
    this.createdAt,
    this.updatedAt,
    required this.serviceStarted,
    this.serviceStartTime,
    this.photosTaken,
  });

  factory ServiceDetailsModel.fromJson(Map<String, dynamic> json) {
    return ServiceDetailsModel(
      id: json['id'] ?? 0,
      serviceRequestId: json['service_request_id'] ?? 0,
      vehiclePhotoUrl: json['vehicle_photo_url'],
      beforePhotoUrl: json['before_photo_url'],
      afterPhotoUrl: json['after_photo_url'],
      initialBatteryLevel: json['initial_battery_level'] != null 
          ? int.tryParse(json['initial_battery_level'].toString())
          : null,
      chargeTimeMinutes: json['charge_time_minutes'] != null 
          ? int.tryParse(json['charge_time_minutes'].toString())
          : null,
      serviceNotes: json['service_notes'],
      serviceStartedAt: json['service_started_at'] != null 
          ? DateTime.tryParse(json['service_started_at'].toString()) 
          : null,
      serviceCompletedAt: json['service_completed_at'] != null 
          ? DateTime.tryParse(json['service_completed_at'].toString()) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
      serviceStarted: json['service_started'] == 1 || 
                      json['service_started'] == true ||
                      json['service_started'] == '1',
      serviceStartTime: json['service_start_time'] != null 
          ? DateTime.tryParse(json['service_start_time'].toString()) 
          : null,
      photosTaken: json['photos_taken'] != null 
          ? (json['photos_taken'] is List 
              ? List<String>.from(json['photos_taken'])
              : [])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_request_id': serviceRequestId,
      'vehicle_photo_url': vehiclePhotoUrl,
      'before_photo_url': beforePhotoUrl,
      'after_photo_url': afterPhotoUrl,
      'initial_battery_level': initialBatteryLevel,
      'charge_time_minutes': chargeTimeMinutes,
      'service_notes': serviceNotes,
      'service_started_at': serviceStartedAt?.toIso8601String(),
      'service_completed_at': serviceCompletedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'service_started': serviceStarted,
      'service_start_time': serviceStartTime?.toIso8601String(),
      'photos_taken': photosTaken,
    };
  }

  // Getters helper para formateo
  String get formattedServiceStartTime {
    if (serviceStartTime == null) return 'No iniciado';
    return _formatDateTime(serviceStartTime!);
  }

  String get formattedServiceCompletedTime {
    if (serviceCompletedAt == null) return 'No completado';
    return _formatDateTime(serviceCompletedAt!);
  }

  String get formattedChargeTime {
    if (chargeTimeMinutes == null) return 'No especificado';
    final hours = chargeTimeMinutes! ~/ 60;
    final minutes = chargeTimeMinutes! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  String get batteryLevelDisplay {
    if (initialBatteryLevel == null) return 'No especificado';
    return '$initialBatteryLevel%';
  }

  String _formatDateTime(DateTime dateTime) {
    // Formato: 15/03/2024 14:30
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Métodos de utilidad
  bool get hasPhotos {
    return vehiclePhotoUrl != null || 
           beforePhotoUrl != null || 
           afterPhotoUrl != null;
  }

  bool get isCompleted {
    return serviceCompletedAt != null;
  }

  bool get hasStarted {
    return serviceStarted && serviceStartTime != null;
  }

  Duration? get serviceDuration {
    if (serviceStartTime != null && serviceCompletedAt != null) {
      return serviceCompletedAt!.difference(serviceStartTime!);
    }
    return null;
  }

  String get formattedServiceDuration {
    final duration = serviceDuration;
    if (duration == null) return 'No disponible';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
}