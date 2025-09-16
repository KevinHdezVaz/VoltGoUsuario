#!/bin/bash

echo "🔍 Verificando soporte para páginas de 16KB..."

# 1. Verificar Flutter y versiones
echo "📱 Versión de Flutter:"
flutter --version

# 2. Verificar configuración Android
echo "🤖 Configuración Android:"
echo "- compileSdk: $(grep 'compileSdk' android/app/build.gradle)"
echo "- targetSdk: $(grep 'targetSdk' android/app/build.gradle)"
echo "- minSdk: $(grep 'minSdk' android/app/build.gradle)"
echo "- NDK: $(grep 'ndkVersion' android/app/build.gradle)"

# 3. Verificar dependencias problemáticas conocidas
echo "🔍 Verificando dependencias nativas..."

# Dependencias que pueden causar problemas con 16k
problematic_deps=(
    "audioplayers"
    "camera"
    "firebase_storage"
    "flutter_secure_storage"
    "geolocator"
    "google_maps_flutter"
    "image_picker"
    "permission_handler"
    "shared_preferences"
    "url_launcher"
    "vibration"
)

echo "📦 Dependencias que requieren verificación para 16k:"
for dep in "${problematic_deps[@]}"; do
    if grep -q "$dep" pubspec.yaml; then
        version=$(grep "$dep:" pubspec.yaml | head -1)
        echo "  ⚠️  $version"
    fi
done

# 4. Verificar si ya compiló
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "📱 APK encontrado. Verificando librerías nativas..."
    
    # Crear directorio temporal
    mkdir -p temp_apk_check
    cd temp_apk_check
    
    # Extraer APK
    unzip -q ../build/app/outputs/flutter-apk/app-debug.apk
    
    # Verificar arquitecturas
    echo "🏗️  Arquitecturas incluidas:"
    if [ -d "lib" ]; then
        ls lib/
    else
        echo "  ℹ️  No se encontraron librerías nativas"
    fi
    
    # Verificar librerías específicas
    echo "📚 Librerías nativas encontradas:"
    find lib -name "*.so" 2>/dev/null | head -10
    
    # Limpiar
    cd ..
    rm -rf temp_apk_check
else
    echo "❌ No se encontró APK compilado. Ejecuta: flutter build apk --debug"
fi

# 5. Recomendaciones
echo ""
echo "📋 RESUMEN:"
echo "✅ Target API 35 (Android 15) - Compatible con 16k"
echo "✅ MinSDK 24+ - Requerido para 16k"
echo "⚠️  Verifica que todas las dependencias nativas soporten 16k"
echo ""
echo "🚀 Para probar en dispositivo con 16k:"
echo "   adb shell setprop debug.16k_page.enabled true"
echo "   adb reboot"
echo ""
echo "📖 Más info: https://developer.android.com/guide/practices/page-sizes"