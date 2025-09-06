class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone; // ✅ AGREGAR este campo
  final String userType;
  final bool hasRegisteredVehicle;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone, // ✅ AGREGAR este parámetro (opcional)
    required this.userType,
    required this.hasRegisteredVehicle,
  });

  // Este 'factory constructor' crea un UserModel a partir de un JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'], // ✅ AGREGAR esta línea
      userType: json['user_type'] ?? 'user',
      // Laravel devuelve 0 o 1 para booleanos, por eso la comparación
      hasRegisteredVehicle: json['has_registered_vehicle'] == 1,
    );
  }

  // ✅ AGREGAR: Método helper para verificar si el perfil está completo
  bool get isProfileComplete {
    return name.trim().isNotEmpty &&
           email.trim().isNotEmpty &&
           phone != null &&
           phone!.trim().isNotEmpty;
  }

  // ✅ OPCIONAL: Método toJson si necesitas enviar el modelo de vuelta al servidor
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'user_type': userType,
      'has_registered_vehicle': hasRegisteredVehicle ? 1 : 0,
    };
  }
  
  // ✅ OPCIONAL: Método copyWith para crear copias modificadas del modelo
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? userType,
    bool? hasRegisteredVehicle,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      hasRegisteredVehicle: hasRegisteredVehicle ?? this.hasRegisteredVehicle,
    );
  }
}