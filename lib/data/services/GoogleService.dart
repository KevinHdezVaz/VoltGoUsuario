import 'dart:convert';
import 'package:Voltgo_User/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

class GoogleAuthService {
  static const _storage = FlutterSecureStorage();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ✅ CONFIGURACIÓN SIMPLE Y FUNCIONAL
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // ✅ USAR TU WEB CLIENT ID DEL GOOGLE-SERVICES.JSON
    serverClientId: '535960810827-se0n0jpib208uo3hgl2c4ju3aroaj844.apps.googleusercontent.com',
  );

  static Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      developer.log('=== INICIANDO GOOGLE SIGN IN ===');
      
      // Limpiar estado previo
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
      } catch (e) {
        developer.log('Limpieza previa: $e');
      }
      
      // Iniciar sesión con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        developer.log('Usuario canceló el signin');
        return GoogleSignInResult(
          success: false,
          error: 'Usuario canceló el inicio de sesión',
        );
      }

      developer.log('Usuario obtenido: ${googleUser.email}');

      // Obtener detalles de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return GoogleSignInResult(
          success: false,
          error: 'No se pudieron obtener los tokens de autenticación',
        );
      }

      developer.log('Tokens obtenidos correctamente');
      
      // Crear credencial para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autenticar con Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        return GoogleSignInResult(
          success: false,
          error: 'Error autenticando con Firebase',
        );
      }

      developer.log('Firebase user: ${userCredential.user!.email}');
      
      // Obtener token de Firebase
      final String? firebaseToken = await userCredential.user!.getIdToken();
      
      if (firebaseToken == null) {
        return GoogleSignInResult(
          success: false,
          error: 'No se pudo obtener el token de Firebase',
        );
      }

      developer.log('Token de Firebase obtenido, enviando al backend...');
      
      // Enviar al backend
      final backendResult = await _sendTokenToBackend(firebaseToken);
      
      if (backendResult.success) {
        if (backendResult.token != null) {
          await _storage.write(key: 'auth_token', value: backendResult.token!);
        }
        
        developer.log('=== GOOGLE SIGN IN EXITOSO ===');
        return GoogleSignInResult(
          success: true,
          user: backendResult.user,
          token: backendResult.token,
        );
      } else {
        developer.log('Error del backend: ${backendResult.error}');
        return GoogleSignInResult(
          success: false,
          error: backendResult.error ?? 'Error del servidor',
        );
      }

    } catch (e, stackTrace) {
      developer.log('=== ERROR EN GOOGLE SIGN IN ===');
      developer.log('Error: $e');
      developer.log('StackTrace: $stackTrace');
      
      return GoogleSignInResult(
        success: false,
        error: 'Error: ${e.toString()}',
      );
    }
  }

  static Future<BackendAuthResult> _sendTokenToBackend(String idToken) async {
    try {
      developer.log('Enviando token al backend...');
      
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/google-login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_token': idToken,
          'app_type': 'user',
          'package_name': 'us.voltgoUser.appc',
        }),
      );

      developer.log('Respuesta del backend: ${response.statusCode}');
      developer.log('Cuerpo: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return BackendAuthResult(
            success: true,
            user: data['user'],
            token: data['token'],
          );
        } else {
          return BackendAuthResult(
            success: false,
            error: data['message'] ?? 'Error en la respuesta del servidor',
          );
        }
      }
      
      final data = jsonDecode(response.body);
      return BackendAuthResult(
        success: false,
        error: data['message'] ?? 'Error de autenticación con código ${response.statusCode}',
      );
    } catch (e) {
      developer.log('Error enviando al backend: $e');
      return BackendAuthResult(
        success: false,
        error: 'Error de conexión con el servidor',
      );
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _storage.delete(key: 'auth_token');
      await _googleSignIn.signOut();
      developer.log('Sign out completado');
    } catch (e) {
      developer.log('Error en signOut: $e');
    }
  }

  static Future<bool> isSignedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }
}

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

class BackendAuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? user;
  final String? token;

  BackendAuthResult({
    required this.success,
    this.error,
    this.user,
    this.token,
  });
}