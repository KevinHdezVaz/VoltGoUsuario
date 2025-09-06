import 'package:shared_preferences/shared_preferences.dart';
import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:Voltgo_User/data/services/auth_api_service.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';

class ProfileCompletionService {
  static const String _profileInProgressKey = 'profile_completion_in_progress';
  static const String _lastProfileCheckKey = 'last_profile_check';

  /// Método principal para verificar el estado completo del perfil desde AppInitializer
  static Future<AppInitializationResult?> checkProfileCompletion() async {
    try {
      print('🔍 ProfileCompletionService: Iniciando verificación completa...');

      // 1. Verificar si hay token de autenticación
      final hasToken = await TokenStorage.hasToken();
      print('🔑 Token presente: $hasToken');

      if (!hasToken) {
        print('❌ No hay token, debe ir al login');
        return AppInitializationResult(
          shouldGoToLogin: true,
          needsCompletion: false,
          canProceedToDashboard: false,
          user: null,
          token: null,
        );
      }

      // 2. Obtener token para pasarlo si es necesario
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ Token es null, debe ir al login');
        return AppInitializationResult(
          shouldGoToLogin: true,
          needsCompletion: false,
          canProceedToDashboard: false,
          user: null,
          token: null,
        );
      }

      // 3. Obtener perfil del usuario
      final userProfile = await AuthService.fetchUserProfile();
      if (userProfile == null) {
        print('❌ No se pudo obtener el perfil del usuario, debe ir al login');
        return AppInitializationResult(
          shouldGoToLogin: true,
          needsCompletion: false,
          canProceedToDashboard: false,
          user: null,
          token: null,
        );
      }

      print('👤 Usuario obtenido: ${userProfile.name} (${userProfile.email})');

      // 4. Verificar completitud del perfil
      final hasPhone = userProfile.phone != null && userProfile.phone!.trim().isNotEmpty;
      final hasName = userProfile.name.trim().isNotEmpty;
      final hasEmail = userProfile.email.trim().isNotEmpty;

      print('📋 Verificación de campos:');
      print('  - Nombre: ${hasName ? "✅" : "❌"} (${userProfile.name})');
      print('  - Email: ${hasEmail ? "✅" : "❌"} (${userProfile.email})');
      print('  - Teléfono: ${hasPhone ? "✅" : "❌"} (${userProfile.phone ?? "null"})');

      final isProfileComplete = hasPhone && hasName && hasEmail;

      if (!isProfileComplete) {
        print('⚠️ Perfil incompleto, debe completar perfil');
        await setProfileCompletionInProgress();
        return AppInitializationResult(
          shouldGoToLogin: false,
          needsCompletion: true,
          canProceedToDashboard: false,
          user: userProfile,
          token: token,
        );
      }

      // 5. Si el perfil está completo, puede proceder al dashboard
      print('✅ Perfil completo, puede proceder al dashboard');
      await clearProfileInProgress(); // Limpiar cualquier flag pendiente
      return AppInitializationResult(
        shouldGoToLogin: false,
        needsCompletion: false,
        canProceedToDashboard: true,
        user: userProfile,
        token: token,
      );

    } catch (e) {
      print('❌ Error en checkProfileCompletion: $e');
      return null; // Retornar null para que AppInitializer maneje el error
    }
  }

  /// Verifica si el perfil del usuario está completo (especialmente el teléfono)
  static Future<bool> isProfileComplete() async {
    try {
      // Obtener el perfil actualizado del servidor
      final userProfile = await AuthService.fetchUserProfile();
      
      if (userProfile == null) {
        print('📱 ProfileCompletionService: No se pudo obtener el perfil del usuario');
        return false;
      }

      // Verificar que tenga todos los campos obligatorios
      final hasPhone = userProfile.phone != null && userProfile.phone!.trim().isNotEmpty;
      final hasName = userProfile.name.trim().isNotEmpty;
      final hasEmail = userProfile.email.trim().isNotEmpty;
      
      print('📱 ProfileCompletionService: Verificación de completitud:');
      print('  - Nombre: ${hasName ? "✅" : "❌"} (${userProfile.name})');
      print('  - Email: ${hasEmail ? "✅" : "❌"} (${userProfile.email})');
      print('  - Teléfono: ${hasPhone ? "✅" : "❌"} (${userProfile.phone ?? "null"})');
      
      final isComplete = hasPhone && hasName && hasEmail;
      
      // Guardar timestamp de la última verificación
      await _saveLastCheckTimestamp();
      
      return isComplete;
    } catch (e) {
      print('❌ ProfileCompletionService: Error verificando perfil: $e');
      return false; // En caso de error, asumir que no está completo para seguridad
    }
  }

  /// Verifica si el usuario necesita completar su perfil
  static Future<ProfileCheckResult> checkIfProfileNeedsCompletion() async {
    try {
      // Evitar verificaciones muy frecuentes (máximo cada 30 segundos)
      if (await _isRecentCheck()) {
        print('📱 ProfileCompletionService: Verificación reciente detectada, omitiendo');
        return ProfileCheckResult(needsCompletion: false, user: null);
      }

      // Verificar si ya hay una verificación en progreso
      if (await isProfileCompletionInProgress()) {
        print('📱 ProfileCompletionService: Completamiento de perfil ya en progreso');
        return ProfileCheckResult(needsCompletion: false, user: null);
      }

      final userProfile = await AuthService.fetchUserProfile();
      
      if (userProfile == null) {
        print('📱 ProfileCompletionService: No se pudo obtener el perfil del usuario');
        return ProfileCheckResult(needsCompletion: false, user: null);
      }

      final isComplete = await isProfileComplete();
      
      if (!isComplete) {
        print('📱 ProfileCompletionService: Perfil incompleto detectado');
        // Marcar que el proceso de completamiento está en progreso
        await setProfileCompletionInProgress();
        return ProfileCheckResult(needsCompletion: true, user: userProfile);
      }

      print('📱 ProfileCompletionService: Perfil está completo');
      return ProfileCheckResult(needsCompletion: false, user: userProfile);
      
    } catch (e) {
      print('❌ ProfileCompletionService: Error en verificación: $e');
      return ProfileCheckResult(needsCompletion: false, user: null);
    }
  }

  /// Verifica si la última verificación fue muy reciente
  static Future<bool> _isRecentCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastProfileCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Verificar si la última verificación fue hace menos de 30 segundos
      return (now - lastCheck) < 30000;
    } catch (e) {
      return false;
    }
  }

  /// Guarda el timestamp de la última verificación
  static Future<void> _saveLastCheckTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastProfileCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Error guardando timestamp de verificación: $e');
    }
  }

  /// Marca que el proceso de completamiento de perfil está en progreso
  static Future<void> setProfileCompletionInProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_profileInProgressKey, true);
      print('📱 ProfileCompletionService: Marcado como en progreso');
    } catch (e) {
      print('❌ Error marcando completamiento en progreso: $e');
    }
  }

  /// Limpia el flag de completamiento en progreso
  static Future<void> clearProfileInProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileInProgressKey);
      print('📱 ProfileCompletionService: Flag de progreso limpiado');
    } catch (e) {
      print('❌ Error limpiando flag de progreso: $e');
    }
  }

  /// Verifica si hay un completamiento de perfil en progreso
  static Future<bool> isProfileCompletionInProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_profileInProgressKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Método de utilidad para verificar solo si el teléfono está presente
  static Future<bool> hasPhoneNumber() async {
    try {
      final userProfile = await AuthService.fetchUserProfile();
      return userProfile?.phone != null && userProfile!.phone!.trim().isNotEmpty;
    } catch (e) {
      print('❌ Error verificando teléfono: $e');
      return false;
    }
  }

  /// Fuerza una nueva verificación ignorando el cache de tiempo
  static Future<ProfileCheckResult> forceProfileCheck() async {
    try {
      // Limpiar el timestamp para forzar una nueva verificación
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastProfileCheckKey);
      
      return await checkIfProfileNeedsCompletion();
    } catch (e) {
      print('❌ Error en verificación forzada: $e');
      return ProfileCheckResult(needsCompletion: false, user: null);
    }
  }

  /// Método de debug para limpiar todos los flags
  static Future<void> clearAllFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileInProgressKey);
      await prefs.remove(_lastProfileCheckKey);
      print('📱 ProfileCompletionService: Todos los flags limpiados');
    } catch (e) {
      print('❌ Error limpiando flags: $e');
    }
  }
}

/// Clase para el resultado de la verificación de perfil (para uso en PassengerMapScreen)
class ProfileCheckResult {
  final bool needsCompletion;
  final UserModel? user;

  ProfileCheckResult({
    required this.needsCompletion,
    required this.user,
  });
}

/// Clase para el resultado de inicialización de la app
class AppInitializationResult {
  final bool shouldGoToLogin;
  final bool needsCompletion;
  final bool canProceedToDashboard;
  final UserModel? user;
  final String? token;

  AppInitializationResult({
    required this.shouldGoToLogin,
    required this.needsCompletion,
    required this.canProceedToDashboard,
    required this.user,
    required this.token,
  });

  @override
  String toString() {
    return 'AppInitializationResult{'
        'shouldGoToLogin: $shouldGoToLogin, '
        'needsCompletion: $needsCompletion, '
        'canProceedToDashboard: $canProceedToDashboard, '
        'user: ${user?.name ?? "null"}, '
        'token: ${token != null ? "present" : "null"}'
        '}';
  }
}