import 'dart:convert';

class ServiceRequestModel {
  final int id;
  final int userId;
  final int? technicianId;
  final int? offeredToTechnicianId;
  final String status;
  final double requestLat;
  final double requestLng;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  
  // NUEVOS CAMPOS PARA COSTOS
  final double? estimatedCost;
  final double? finalCost;
  final double? baseCost;
  final double? distanceCost;
  final double? timeCost;
  final double? tipAmount;
  
  // NUEVOS CAMPOS PARA FECHAS ADICIONALES
  final DateTime? enRouteAt;
  final DateTime? arrivedAt;
  final DateTime? serviceStartedAt;
  
  // CAMPOS PARA CANCELACIÓN
  final String? cancellationReason;
  final Map<String, dynamic>? cancellationDetails;
  final double? cancellationFee;
  
  // CAMPO PARA ESTADO DE PAGO
  final String? paymentStatus;
  final DateTime? paidAt;

  // Datos del técnico y usuario (cuando están disponibles)
  final TechnicianData? technician;
  final UserData? user;

  ServiceRequestModel({
    required this.id,
    required this.userId,
    this.technicianId,
    this.offeredToTechnicianId,
    required this.status,
    required this.requestLat,
    required this.requestLng,
    required this.requestedAt,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.estimatedCost,
    this.finalCost,
    this.baseCost,
    this.distanceCost,
    this.timeCost,
    this.tipAmount,
    this.enRouteAt,
    this.arrivedAt,
    this.serviceStartedAt,
    this.cancellationReason,
    this.cancellationDetails,
    this.cancellationFee,
    this.paymentStatus,
    this.paidAt,
    this.technician,
    this.user,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      technicianId: json['technician_id'],
      offeredToTechnicianId: json['offered_to_technician_id'],
      status: json['status'] ?? 'pending',
      requestLat: double.parse((json['request_lat'] ?? 0.0).toString()),
      requestLng: double.parse((json['request_lng'] ?? 0.0).toString()),
      requestedAt: DateTime.parse(json['requested_at'] ??
          json['created_at'] ??
          DateTime.now().toIso8601String()),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      
      // NUEVOS CAMPOS DE COSTOS
      estimatedCost: json['estimated_cost'] != null 
          ? double.parse(json['estimated_cost'].toString())
          : null,
      finalCost: json['final_cost'] != null 
          ? double.parse(json['final_cost'].toString())
          : null,
      baseCost: json['base_cost'] != null 
          ? double.parse(json['base_cost'].toString())
          : null,
      distanceCost: json['distance_cost'] != null 
          ? double.parse(json['distance_cost'].toString())
          : null,
      timeCost: json['time_cost'] != null 
          ? double.parse(json['time_cost'].toString())
          : null,
      tipAmount: json['tip_amount'] != null 
          ? double.parse(json['tip_amount'].toString())
          : null,
      
      // NUEVOS CAMPOS DE FECHAS
      enRouteAt: json['en_route_at'] != null
          ? DateTime.parse(json['en_route_at'])
          : null,
      arrivedAt: json['arrived_at'] != null
          ? DateTime.parse(json['arrived_at'])
          : null,
      serviceStartedAt: json['service_started_at'] != null
          ? DateTime.parse(json['service_started_at'])
          : null,
      
      // CAMPOS DE CANCELACIÓN
      cancellationReason: json['cancellation_reason'],
      cancellationDetails: json['cancellation_details'] is Map<String, dynamic>
          ? json['cancellation_details']
          : json['cancellation_details'] is String
              ? jsonDecode(json['cancellation_details'])
              : null,
      cancellationFee: json['cancellation_fee'] != null 
          ? double.parse(json['cancellation_fee'].toString())
          : null,
      
      // ESTADO DE PAGO
      paymentStatus: json['payment_status'],
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'])
          : null,

      // RELACIONES
      technician: json['technician'] != null
          ? TechnicianData.fromJson(json['technician'])
          : null,
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'technician_id': technicianId,
      'offered_to_technician_id': offeredToTechnicianId,
      'status': status,
      'request_lat': requestLat,
      'request_lng': requestLng,
      'requested_at': requestedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'estimated_cost': estimatedCost,
      'final_cost': finalCost,
      'base_cost': baseCost,
      'distance_cost': distanceCost,
      'time_cost': timeCost,
      'tip_amount': tipAmount,
      'en_route_at': enRouteAt?.toIso8601String(),
      'arrived_at': arrivedAt?.toIso8601String(),
      'service_started_at': serviceStartedAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'cancellation_details': cancellationDetails,
      'cancellation_fee': cancellationFee,
      'payment_status': paymentStatus,
      'paid_at': paidAt?.toIso8601String(),
      'technician': technician?.toJson(),
      'user': user?.toJson(),
    };
  }

  // MÉTODOS HELPER PARA FECHAS FORMATEADAS
  String get formattedDate {
    final date = acceptedAt ?? requestedAt;
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  String get formattedTime {
    final date = acceptedAt ?? requestedAt;
    return '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    final date = acceptedAt ?? requestedAt;
    return '${formattedDate} ${formattedTime}';
  }

  // MÉTODOS PARA VALIDAR ESTADOS Y CAPACIDADES
  bool canChat() {
    return ['accepted', 'en_route', 'on_site', 'charging'].contains(status);
  }

  bool get isActive {
    return ['pending', 'accepted', 'en_route', 'on_site', 'charging'].contains(status);
  }

  bool get isCompleted {
    return status == 'completed';
  }

  bool get isCancelled {
    return status == 'cancelled';
  }

  bool get isFinished {
    return ['completed', 'cancelled'].contains(status);
  }

  bool get canBeCancelled {
    return ['pending', 'accepted', 'en_route'].contains(status);
  }

  // MÉTODOS PARA OBTENER INFORMACIÓN DE COSTOS
  double get totalCost {
    return (finalCost ?? estimatedCost ?? 0.0);
  }

  bool get hasCost {
    return finalCost != null || estimatedCost != null;
  }

  String get costDisplay {
    if (finalCost != null) {
      return '\$${finalCost!.toStringAsFixed(2)}';
    } else if (estimatedCost != null) {
      return '~\$${estimatedCost!.toStringAsFixed(2)}';
    }
    return 'Sin costo';
  }

  // MÉTODOS PARA DURACIÓN DEL SERVICIO
  Duration? get serviceDuration {
    if (serviceStartedAt != null && completedAt != null) {
      return completedAt!.difference(serviceStartedAt!);
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

  // MÉTODO PARA OBTENER EL TÉCNICO ASIGNADO
  String get technicianName {
    return technician?.name ?? 'Técnico no asignado';
  }

  String get technicianDisplayName {
    if (technician != null) {
      return technician!.name;
    }
    return 'Esperando asignación...';
  }

  // MÉTODOS PARA INFORMACIÓN DE PAGO
  bool get isPaid {
    return paymentStatus == 'paid';
  }

  bool get isPending {
    return paymentStatus == 'pending';
  }

  String get paymentStatusDisplay {
    switch (paymentStatus?.toLowerCase()) {
      case 'paid':
        return 'Pagado';
      case 'pending':
        return 'Pendiente';
      case 'failed':
        return 'Fallido';
      case 'refunded':
        return 'Reembolsado';
      default:
        return 'No especificado';
    }
  }
}

// Las clases TechnicianData, TechnicianProfile, VehicleDetails y UserData 
// permanecen igual que en tu código original
class TechnicianData {
  final int id;
  final String name;
  final String? email;
  final TechnicianProfile? profile;

  TechnicianData({
    required this.id,
    required this.name,
    this.email,
    this.profile,
  });

  factory TechnicianData.fromJson(Map<String, dynamic> json) {
    return TechnicianData(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Técnico',
      email: json['email'],
      profile: json['technician_profile'] != null
          ? TechnicianProfile.fromJson(json['technician_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'technician_profile': profile?.toJson(),
    };
  }
}

class TechnicianProfile {
  final int userId;
  final String? status;
  final String? currentLat;
  final String? currentLng;
  final String? averageRating;
  final Map<String, dynamic>? vehicleDetails;
  final String? availableConnectors;
  final String? licenseNumber;

  TechnicianProfile({
    required this.userId,
    this.status,
    this.currentLat,
    this.currentLng,
    this.averageRating,
    this.vehicleDetails,
    this.availableConnectors,
    this.licenseNumber,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    return TechnicianProfile(
      userId: json['user_id'] ?? 0,
      status: json['status']?.toString(),
      currentLat: json['current_lat']?.toString(),
      currentLng: json['current_lng']?.toString(),
      averageRating: json['average_rating']?.toString(),
      vehicleDetails: json['vehicle_details'] is Map<String, dynamic>
          ? json['vehicle_details']
          : null,
      availableConnectors: json['available_connectors']?.toString(),
      licenseNumber: json['license_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'average_rating': averageRating,
      'vehicle_details': vehicleDetails,
      'available_connectors': availableConnectors,
      'license_number': licenseNumber,
    };
  }

  String? get vehicleMake => vehicleDetails?['make']?.toString();
  String? get vehicleModel => vehicleDetails?['model']?.toString();
  String? get vehicleYear => vehicleDetails?['year']?.toString();
  String? get vehiclePlate => vehicleDetails?['plate']?.toString();
  String? get vehicleColor => vehicleDetails?['color']?.toString();
  String? get vehicleConnectorType => vehicleDetails?['connector_type']?.toString();

  String get vehicleDescription {
    if (vehicleDetails == null || vehicleDetails!.isEmpty) {
      return 'Vehículo no especificado';
    }

    final parts = <String>[];
    if (vehicleYear != null) parts.add(vehicleYear!);
    if (vehicleMake != null) parts.add(vehicleMake!);
    if (vehicleModel != null) parts.add(vehicleModel!);
    if (vehicleColor != null) parts.add('(${vehicleColor!})');

    return parts.isNotEmpty ? parts.join(' ') : 'Vehículo no especificado';
  }
}

class VehicleDetails {
  final String make;
  final String model;
  final String year;
  final String plate;
  final String color;
  final String connectorType;

  VehicleDetails({
    required this.make,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    required this.connectorType,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? '',
      plate: json['plate'] ?? '',
      color: json['color'] ?? '',
      connectorType: json['connector_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'plate': plate,
      'color': color,
      'connector_type': connectorType,
    };
  }
}

class UserData {
  final int id;
  final String name;
  final String? email;

  UserData({
    required this.id,
    required this.name,
    this.email,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Usuario',
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}