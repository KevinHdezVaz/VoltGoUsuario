import 'dart:async';
 import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static AudioPlayer? _player;
  static bool _isPlaying = false;
  static bool _isLooping = false;
  static bool _isDisposed = false;
  static Timer? _vibrationTimer;

  // Inicializar el player de forma lazy
  static AudioPlayer _getPlayer() {
    if (_player == null || _isDisposed) {
      _player = AudioPlayer();
      _isDisposed = false;
      print('🎵 AudioPlayer inicializado');
    }
    return _player!;
  }

  /// Reproduce sonido y vibración para notificaciones
  static Future<void> playNotification({
    bool loop = false,
    bool includeVibration = true,
    VibrationPattern vibrationPattern = VibrationPattern.incoming,
  }) async {
    try {
      // Verificar si ya está reproduciendo el mismo tipo de sonido
      if (_isPlaying && loop == _isLooping) {
        print('🎵 Ya está reproduciendo el mismo tipo de notificación');
        return;
      }

      print('🎵 Iniciando notificación (sonido: ✓, vibración: $includeVibration, loop: $loop)');

      final player = _getPlayer();
      
      // Detener cualquier reproducción actual
      if (_isPlaying) {
        await stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _isPlaying = true;
      _isLooping = loop;

      // Iniciar vibración si está habilitada
      if (includeVibration) {
        _startVibration(vibrationPattern, loop);
      }

      if (loop) {
        // Modo loop
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource('sounds/sonido.mp3'));
        print('🔄 Notificación en modo loop iniciada');
      } else {
        // Modo normal (una sola vez)
        await player.setReleaseMode(ReleaseMode.stop);
        await player.play(AssetSource('sounds/sonido.mp3'));
        print('▶️ Notificación normal iniciada');
        
        // Escuchar cuando termine la reproducción
        player.onPlayerComplete.listen((event) {
          _isPlaying = false;
          _isLooping = false;
          _stopVibration();
          print('✅ Notificación completada');
        });
      }
    } catch (e) {
      print('❌ Error reproduciendo notificación: $e');
      _isPlaying = false;
      _isLooping = false;
      _stopVibration();
    }
  }

  /// Inicia la vibración según el patrón especificado
  static void _startVibration(VibrationPattern pattern, bool loop) {
    _stopVibration(); // Detener vibración anterior

    switch (pattern) {
      case VibrationPattern.incoming:
        _vibrateIncomingRequest(loop);
        break;
      case VibrationPattern.urgent:
        _vibrateUrgent(loop);
        break;
      case VibrationPattern.gentle:
        _vibrateGentle(loop);
        break;
      case VibrationPattern.single:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Patrón de vibración para solicitudes entrantes
  static void _vibrateIncomingRequest(bool loop) {
    // Vibración inicial fuerte
    HapticFeedback.heavyImpact();
    
    if (loop) {
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        HapticFeedback.heavyImpact();
        
        // Vibración secundaria más suave después de 300ms
        Future.delayed(const Duration(milliseconds: 300), () {
          HapticFeedback.mediumImpact();
        });
      });
    } else {
      // Solo una secuencia de vibración
      Future.delayed(const Duration(milliseconds: 300), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Patrón de vibración urgente (más intenso)
  static void _vibrateUrgent(bool loop) {
    // Vibración muy fuerte inicial
    HapticFeedback.heavyImpact();
    
    if (loop) {
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        // Secuencia de 3 vibraciones fuertes
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.heavyImpact();
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          HapticFeedback.heavyImpact();
        });
      });
    }
  }

  /// Patrón de vibración suave
  static void _vibrateGentle(bool loop) {
    HapticFeedback.lightImpact();
    
    if (loop) {
      _vibrationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Detiene la vibración
  static void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  /// Detiene tanto el sonido como la vibración
  static Future<void> stop() async {
    try {
      if (_player != null && !_isDisposed) {
        print('⏹️ Deteniendo notificación...');
        await _player!.stop();
        _isPlaying = false;
        _isLooping = false;
        _stopVibration();
        print('✅ Notificación detenida');
      }
    } catch (e) {
      print('❌ Error deteniendo notificación: $e');
    }
  }

  /// Libera los recursos
  static void dispose() {
    try {
      if (_player != null && !_isDisposed) {
        print('🗑️ Liberando NotificationService...');
        _player!.dispose();
        _player = null;
        _isDisposed = true;
        _isPlaying = false;
        _isLooping = false;
        _stopVibration();
        print('✅ NotificationService liberado');
      }
    } catch (e) {
      print('❌ Error liberando NotificationService: $e');
    }
  }

  /// Reinicializa el servicio
  static void reinitialize() {
    if (_isDisposed || _player == null) {
      print('🔄 Reinicializando NotificationService...');
      _player = AudioPlayer();
      _isDisposed = false;
      _isPlaying = false;
      _isLooping = false;
      _stopVibration();
    }
  }

  // Métodos de estado
  static bool get isPlaying => _isPlaying;
  static bool get isLooping => _isLooping;
  static bool get isDisposed => _isDisposed;
  static bool get isVibrating => _vibrationTimer?.isActive ?? false;

  // Métodos de conveniencia para diferentes tipos de notificaciones
  
  /// Notificación para solicitudes entrantes (sonido + vibración en loop)
  static Future<void> playIncomingRequestNotification() async {
    await playNotification(
      loop: true,
      includeVibration: false,
      vibrationPattern: VibrationPattern.incoming,
    );
  }

  /// Notificación urgente (para cancelaciones o errores críticos)
  static Future<void> playUrgentNotification() async {
    await playNotification(
      loop: false,
      includeVibration: true,
      vibrationPattern: VibrationPattern.urgent,
    );
  }

  /// Notificación suave (para confirmaciones)
  static Future<void> playGentleNotification() async {
    await playNotification(
      loop: false,
      includeVibration: true,
      vibrationPattern: VibrationPattern.gentle,
    );
  }

  /// Solo vibración (sin sonido)
  static void vibrateOnly(VibrationPattern pattern) {
    _startVibration(pattern, false);
  }
}

/// Enum para diferentes patrones de vibración
enum VibrationPattern {
  incoming,    // Para solicitudes entrantes
  urgent,      // Para situaciones urgentes
  gentle,      // Para confirmaciones suaves
  single,      // Una sola vibración
}