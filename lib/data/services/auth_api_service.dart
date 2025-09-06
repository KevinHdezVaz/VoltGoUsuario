import 'dart:convert';
import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:Voltgo_User/data/models/LOGIN/ResetPasswordModel.dart';
import 'package:Voltgo_User/data/models/LOGIN/login_request_model.dart';
import 'package:Voltgo_User/data/models/LOGIN/logout_response.dart';
import 'package:Voltgo_User/data/services/UserCacheService.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';
import 'dart:developer' as developer;

// NUEVAS IMPORTACIONES PARA GOOGLE SIGN IN
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // NUEVA CONFIGURACIÓN PARA GOOGLE SIGN IN
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/login');
    final body = LoginRequest(
      email: email,
      password: password,
    ).toJson();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        if (loginResponse.token.isNotEmpty) {
          await TokenStorage.saveToken(loginResponse.token);
        }
        return loginResponse;
      } else {
        String errorMessage = 'Credenciales inválidas.';
        try {
          errorMessage = jsonDecode(response.body)['message'] ?? errorMessage;
        } catch (e) {/* Ignora errores de parseo */}
        return LoginResponse(token: '', error: errorMessage);
      }
    } catch (e) {
      return LoginResponse(token: '', error: 'Error de conexión: $e');
    }
  }


// Agregar este método en tu clase AuthService

static Future<RegisterResponse> updateUserProfile({
  String? phone,
  String? name,
  String? email,
}) async {
  final token = await TokenStorage.getToken();
  if (token == null) {
    return RegisterResponse(
      success: false,
      error: 'No se encontró token de autenticación',
    );
  }

   final url = Uri.parse('${Constants.baseUrl}/auth/user/profile');

  final Map<String, dynamic> body = {};
  
  if (phone != null) body['phone'] = phone;
  if (name != null) body['name'] = name;
  if (email != null) body['email'] = email;

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('Update profile response: ${response.statusCode}');
    print('Update profile body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      
      // Si el backend devuelve un nuevo token, guardarlo
      if (jsonResponse['token'] != null) {
        await TokenStorage.saveToken(jsonResponse['token']);
      }
      
      return RegisterResponse(
        success: true,
        user: jsonResponse['user'] != null 
            ? UserModel.fromJson(jsonResponse['user']) 
            : null,
        token: jsonResponse['token'] ?? token,
      );
    } else {
      String errorMessage = 'Error actualizando perfil';
      try {
        final jsonResponse = jsonDecode(response.body);
        errorMessage = jsonResponse['message'] ?? 
                      jsonResponse['error'] ?? 
                      errorMessage;
      } catch (e) {
        /* Mantener mensaje por defecto */
      }
      
      return RegisterResponse(
        success: false,
        error: errorMessage,
      );
    }
  } catch (e) {
    print('Exception updating profile: $e');
    return RegisterResponse(
      success: false,
      error: 'Error de conexión: ${e.toString()}',
    );
  }
}


  // NUEVO MÉTODO PARA LOGIN CON GOOGLE
  static Future<GoogleSignInResult> loginWithGoogle() async {
    try {
      developer.log('Iniciando Google Sign In para usuarios...');
      
      // 1. Iniciar sesión con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        developer.log('Usuario canceló el inicio de sesión con Google');
        return GoogleSignInResult(
          success: false,
          error: 'El usuario canceló el inicio de sesión',
        );
      }

      developer.log('Usuario de Google obtenido: ${googleUser.email}');

      // 2. Obtener detalles de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Crear credencial para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // 5. Obtener el ID Token de Firebase
      final String? idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        developer.log('No se pudo obtener el token de Firebase');
        return GoogleSignInResult(
          success: false,
          error: 'No se pudo obtener el token de Firebase',
        );
      }

      developer.log('Token de Firebase obtenido');

      // 6. Enviar el token al backend
      final backendResult = await _sendTokenToBackend(idToken);
      
      if (backendResult.success) {
        developer.log('Login con Google exitoso');
        return GoogleSignInResult(
          success: true,
          user: backendResult.user,
          token: backendResult.token,
        );
      } else {
        developer.log('Error en backend: ${backendResult.error}');
        return GoogleSignInResult(
          success: false,
          error: backendResult.error ?? 'Error en el servidor',
        );
      }

    } catch (e) {
      developer.log('Error en signInWithGoogle: $e');
      return GoogleSignInResult(
        success: false,
        error: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // MÉTODO PRIVADO PARA ENVIAR TOKEN AL BACKEND
  static Future<GoogleSignInResult> _sendTokenToBackend(String idToken) async {
    try {
      final url = Uri.parse('${Constants.baseUrl}/auth/google-login');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_token': idToken,
          'app_type': 'user', // Para app de usuarios
          'package_name': 'us.voltgoUser.appc', // Identificador de la app
        }),
      );

      developer.log('Respuesta Google Backend - Status: ${response.statusCode}');
      developer.log('Cuerpo Google Backend: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true) {
          final token = jsonResponse['token'] as String?;
          final user = jsonResponse['user'] as Map<String, dynamic>?;
          
          if (token != null && token.isNotEmpty) {
            await TokenStorage.saveToken(token);
            developer.log('Token de Google guardado exitosamente');
            return GoogleSignInResult(
              success: true,
              user: user,
              token: token,
            );
          } else {
            return GoogleSignInResult(
              success: false,
              error: 'No se recibió el token del servidor',
            );
          }
        } else {
          return GoogleSignInResult(
            success: false,
            error: jsonResponse['message'] ?? 'Error en la autenticación',
          );
        }
      } else {
        String errorMessage = 'Error en la autenticación con Google';
        try {
          final jsonResponse = jsonDecode(response.body);
          errorMessage = jsonResponse['message'] ?? errorMessage;
        } catch (e) {
          /* Mantener el mensaje por defecto */
        }

        return GoogleSignInResult(success: false, error: errorMessage);
      }
    } catch (e) {
      developer.log('Excepción enviando token al backend: $e');
      return GoogleSignInResult(
        success: false,
        error: 'Error de conexión con el servidor',
      );
    }
  }

  static Future<RegisterResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String userType,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/register');
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'user_type': userType,
      if (phone != null) 'phone': phone,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return RegisterResponse.fromJson(jsonDecode(response.body));
      } else {
        String errorMessage = 'Error en el registro.';
        try {
          final jsonResponse = jsonDecode(response.body);
          errorMessage = jsonResponse['errors']?.values?.first[0] ??
              jsonResponse['message'] ??
              errorMessage;
        } catch (e) {/* Ignora errores de parseo */}
        return RegisterResponse(success: false, error: errorMessage);
      }
    } catch (e) {
      return RegisterResponse(success: false, error: 'Error de conexión: $e');
    }
  }


// Agregar este método en AuthService
static Future<http.Response> _makeAuthenticatedRequest(
  Future<http.Response> Function() request
) async {
  try {
    final response = await request();
    
    // Si el token es inválido/expirado, limpiar automáticamente
    if (response.statusCode == 401 || response.statusCode == 403) {
      developer.log('Token inválido detectado, limpiando datos...');
      await TokenStorage.deleteToken();
      await UserCacheService.clearUserData();
    }
    
    return response;
  } catch (e) {
    developer.log('Error en request autenticado: $e');
    rethrow;
  }
}

  static Future<UserModel?> fetchUserProfile() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      print('No token found, cannot fetch profile.');
      return null;
    }

    final url = Uri.parse('${Constants.baseUrl}/user/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to fetch profile: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception while fetching profile: $e');
      return null;
    }
  }

  // MÉTODO LOGOUT ACTUALIZADO PARA INCLUIR GOOGLE
  static Future<void> logout() async {
    final token = await TokenStorage.getToken();
    
    // Cerrar sesión de Google y Firebase
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      developer.log('Sesiones de Google y Firebase cerradas');
    } catch (e) {
      developer.log('Error cerrando sesión de Google/Firebase: $e');
    }

    if (token == null) {
      await TokenStorage.deleteToken();
      await UserCacheService.clearUserData();
      return;
    }

    final url = Uri.parse('${Constants.baseUrl}/logout');
    print('URL de logout: $url');

    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print('Exception during logout request: $e');
    } finally {
      await TokenStorage.deleteToken();
      await UserCacheService.clearUserData();
      print('Local user data and token cleared.');
    }
  }

  static Future<String?> getStoredToken() async {
    final token = await TokenStorage.getToken();
    print('Obteniendo token almacenado: $token');
    return token;
  }

  static Future<bool> isLoggedIn() async {
    return await TokenStorage.hasToken();
  }

  // MÉTODO PARA VERIFICAR SI ESTÁ LOGUEADO CON GOOGLE
  static Future<bool> isSignedInWithGoogle() async {
    final googleUser = await _googleSignIn.isSignedIn();
    final firebaseUser = _auth.currentUser;
    return googleUser && firebaseUser != null;
  }

  static Future<PasswordResetResponse> requestPasswordReset(
      String email) async {
    final url = Uri.parse('${Constants.baseUrl}/user/reset-password/$email');
    print('Solicitando reset de contraseña - URL: $url');

    try {
      final response = await http.get(url);
      print('Respuesta recibida - Status Code: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return PasswordResetResponse(
            success: true,
            message: jsonResponse['message'] ?? 'Código enviado correctamente',
          );
        } catch (e) {
          print('Error al parsear JSON: $e');
          return PasswordResetResponse(
            success: false,
            message: 'Error al procesar la respuesta del servidor',
          );
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Error desconocido';
        print('Error en reset: $errorMsg');
        return PasswordResetResponse(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      print('Excepción en requestPasswordReset: $e');
      return PasswordResetResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  static Future<PasswordResetResponse> verifyMfaCode({
    required String email,
    required String code,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/user/reset-password/$email');
    final body = MfaVerification(email: email, code: code).toJson();
    print('Validando MFA - URL: $url');
    print('Cuerpo de la solicitud: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('Respuesta recibida - Status Code: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          print('Validación MFA exitosa');
          return PasswordResetResponse(
            success: true,
            message:
                jsonResponse['message'] ?? 'Código verificado correctamente',
          );
        } catch (e) {
          print('Error al parsear JSON: $e');
          return PasswordResetResponse(
            success: false,
            message: 'Error al procesar la respuesta del servidor',
          );
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Código inválido';
        print('Error en MFA: $errorMsg');
        return PasswordResetResponse(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      print('Excepción en verifyMfaCode: $e');
      return PasswordResetResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  static Future<PasswordResetResponse> setNewPassword({
    required String email,
    required String newPass,
    required String newPassCheck,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/user/reset-password/$email');
    final body = NewPasswordData(
      email: email,
      newPass: newPass,
      newPassCheck: newPassCheck,
    ).toJson();
    print('Cambiando contraseña - URL: $url');
    print('Cuerpo de la solicitud: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('Respuesta recibida - Status Code: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Cambio de contraseña exitoso');
        return PasswordResetResponse(
          success: true,
          message:
              jsonResponse['message'] ?? 'Contraseña cambiada correctamente',
        );
      } else {
        final jsonResponse = jsonDecode(response.body);
        final errorMsg =
            jsonResponse['message'] ?? 'Error al cambiar contraseña';
        print('Error en setNewPassword: $errorMsg');
        return PasswordResetResponse(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      print('Excepción en setNewPassword: $e');
      return PasswordResetResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }
}

// NUEVA CLASE PARA GOOGLE SIGN IN RESULT
class GoogleSignInResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? user;
  final String? token;

  GoogleSignInResult({
    required this.success,
    this.error,
    this.user,
    this.token,
  });
}

class RegisterResponse {
  final bool success;
  final String? token;
  final UserModel? user;
  final String? error;

  RegisterResponse({required this.success, this.token, this.user, this.error});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: true,
      token: json['token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}