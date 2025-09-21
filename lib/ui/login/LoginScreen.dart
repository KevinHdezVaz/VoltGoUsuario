import 'dart:convert';
import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:Voltgo_User/data/services/GoogleService.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/login/CompleteProfileScreen.dart';
import 'package:Voltgo_User/ui/login/add_vehicle_screen.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
 import 'package:Voltgo_User/utils/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:Voltgo_User/data/services/auth_api_service.dart';
import 'package:Voltgo_User/ui/MenuPage/DashboardScreen.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/ui/login/ForgotPasswordScreen.dart';
import 'package:Voltgo_User/ui/login/RegisterScreen.dart';
import 'package:Voltgo_User/utils/AnimatedTruckProgress.dart';
import 'package:Voltgo_User/utils/encryption_utils.dart';
import 'dart:developer' as developer; // ✅ AGREGAR IMPORT

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _emailController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;
    });
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);

    if (!_isButtonEnabled || _isLoading) return;

    setState(() => _isLoading = true);
    _animationController.repeat();

    try {
      final loginResponse = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _animationController.stop();
      if (!mounted) return;

      if (loginResponse.token.isNotEmpty && loginResponse.user != null) {
        _navigateAfterAuth(loginResponse.user!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginResponse.error ?? l10n.incorrectUserPassword),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.serverConnectionError),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // En tu LoginScreen, actualiza el método _navigateAfterAuth:

void _navigateAfterAuth(UserModel user) {
  // ✅ VERIFICAR SI EL PERFIL ESTÁ COMPLETO
  if (!_isProfileComplete(user)) {
    // Si el perfil no está completo, ir a CompleteProfileScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => CompleteProfileScreen(
          user: user,
          token: TokenStorage.getToken().toString(), // Asegurar que tienes el token
        ),
      ),
      (route) => false,
    );
    return;
  }

  // ✅ SI EL PERFIL ESTÁ COMPLETO, VERIFICAR VEHÍCULO
  if (user.hasRegisteredVehicle) {
    // Si ya tiene vehículo, va a la pantalla principal
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BottomNavBar()),
      (route) => false,
    );
  } else {
    // Si NO tiene vehículo, muestra la pantalla de registro de vehículo
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(
          onVehicleAdded: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const BottomNavBar()),
              (route) => false,
            );
          },
        ),
      ),
      (route) => false,
    );
  }
}

// ✅ AGREGAR ESTE MÉTODO HELPER EN LoginScreen
bool _isProfileComplete(UserModel user) {
  return user.name.trim().isNotEmpty &&
         user.email.trim().isNotEmpty &&
         user.phone != null &&
         user.phone!.trim().isNotEmpty;
}



Future<void> _signInWithApple() async {
  final l10n = AppLocalizations.of(context);
  
  if (_isLoading) return;

  // Verificar si Apple Sign In está disponible
  final isAvailable = await AuthService.isAppleSignInAvailable();
  if (!isAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Apple Sign In no está disponible en este dispositivo'),
        backgroundColor: Colors.red.shade600,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);
  _animationController.repeat();

  try {
    developer.log('Iniciando Apple Sign In...');
    
    final result = await AuthService.loginWithApple();
    
    _animationController.stop();
    if (!mounted) return;

    if (result.success && result.user != null && result.token != null) {
      developer.log('Apple Sign In exitoso');
      
      // Crear modelo de usuario desde la respuesta
      final userMap = result.user!;
      final userModel = UserModel.fromJson(userMap);
      
      // Verificar si necesita completar perfil
      final phone = userMap['phone'];
      
      if (phone == null || phone.toString().trim().isEmpty) {
        developer.log('Usuario necesita completar perfil - redirigiendo a CompleteProfileScreen');
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CompleteProfileScreen(
              user: userModel,
              token: result.token!,
            ),
          ),
          (route) => false,
        );
      } else {
        developer.log('Usuario ya tiene perfil completo - navegando normalmente');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.welcomeBack),
            backgroundColor: Colors.green,
          ),
        );
        
        _navigateAfterAuth(userModel);
      }
    } else {
      // Mostrar error (solo si no fue cancelación)
if (result.error != 'The user cancelled the login') {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? l10n.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    _animationController.stop();
    developer.log('Excepción en Apple Sign In: $e');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorOccurred}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildForm(),
                    const SizedBox(height: 24),
                    _buildSocialLogins(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: AnimatedTruckProgress(
                animation: _animationController,
              ),
            ),
        ],
      ),
    );
  }

  
  Widget _buildSocialLogins() {
  final l10n = AppLocalizations.of(context);
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  final isAndroid = Theme.of(context).platform == TargetPlatform.android;

  return Column(
    children: [
      Row(
        children: [
          const Expanded(child: Divider(thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              l10n.or,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
      const SizedBox(height: 24),
      
      // Botón de Google - Siempre visible en ambas plataformas
      _buildSocialButton(
         assetName: 'assets/images/gugel.png',
        text: l10n.signInWithGoogle,
        onPressed: _isLoading ? null : _signUpWithGoogle,
      ),
      
      // Botón de Apple - Solo visible en iOS
      if (isIOS) ...[
        const SizedBox(height: 12),
        _buildSocialButton(
          assetName: 'assets/images/appell.png',
          text: l10n.signInWithApple,
          colorIcon: Colors.white,
          backgroundColor: Colors.blueGrey, // Color típico de Apple
          textColor: Colors.white,
          onPressed: _isLoading ? null : _signInWithApple,
        ),
      ],
    ],
  );
}


  Widget _buildSocialButton({
    required String assetName,
    required String text,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
    Color? colorIcon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Image.asset(assetName, height: 22, width: 22, color: colorIcon,),
        label: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.white,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          side: BorderSide(color: AppColors.gray300),
        ),
      ),
    );
  }


  
 Future<void> _signUpWithGoogle() async {
  final l10n = AppLocalizations.of(context);
  
  if (_isLoading) return;

  setState(() => _isLoading = true);
  _animationController.repeat();

  try {
    developer.log('Iniciando Google Sign Up...');
    
    final result = await GoogleAuthService.signInWithGoogle();
    
    if (!mounted) {
      _animationController.stop();
      return;
    }
    
    _animationController.stop();

    if (result.success && result.user != null && result.token != null) {
      developer.log('Google Sign Up exitoso');
      
      // Guardar el token inmediatamente
      await TokenStorage.saveToken(result.token!);
      
      // Crear modelo de usuario desde la respuesta
      final userMap = result.user!;
      final userModel = UserModel.fromJson(userMap);
      
      // Verificar si necesita completar perfil
      final phone = userMap['phone'];
      
      if (phone == null || phone.toString().trim().isEmpty) {
        developer.log('Usuario necesita completar perfil - redirigiendo a CompleteProfileScreen');
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CompleteProfileScreen(
              user: userModel,
              token: result.token!,
            ),
          ),
          (route) => false,
        );
      } else {
        developer.log('Usuario ya tiene perfil completo - navegando normalmente');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.welcomeSuccessfulRegistration),
              backgroundColor: Colors.green,
            ),
          );
          
          _navigateAfterAuth(userModel);
        }
      }
    } else {
      // Error en Google Sign Up - pero verificar que no sea cancelación
      if (result.error != null && 
          !result.error!.toLowerCase().contains('cancel') &&
          !result.error!.toLowerCase().contains('user_cancelled')) {
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? l10n.errorOccurred),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  } catch (e) {
    developer.log('Excepción en Google Sign Up: $e');
    
    if (mounted) {
      _animationController.stop();
      
      // No mostrar error si es cancelación del usuario
      final errorMessage = e.toString().toLowerCase();
      if (!errorMessage.contains('cancel') && 
          !errorMessage.contains('user_cancelled')) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorOccurred}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


  Widget _buildBackground(BuildContext context) {
    return Stack(children: [
      Positioned(
        bottom: 0,
        left: 0,
        child: Image.asset(
          'assets/images/rectangle3.png',
          width: MediaQuery.of(context).size.width * 0.5,
          fit: BoxFit.contain,
          color: AppColors.primary,
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/images/logoapp.png',
            height: 160,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.welcomeUser,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: l10n.email,
          hint: l10n.enterEmail,
          controller: _emailController,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(controller: _passwordController),
        const SizedBox(height: 20),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isButtonEnabled && !_isLoading ? _login : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled && !_isLoading
                    ? AppColors.brandBlue
                    : AppColors.gray300,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                elevation: 0),
            child: Text(l10n.signIn,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white)),
          ),
        )
      ],
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.noAccount,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  )),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  );
                },
                child: Text(l10n.createHere,
                    style: TextStyle(
                        color: AppColors.brandBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTextField(
      {required String label,
      required String hint,
      required TextEditingController controller}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(
                      color: AppColors.brandBlue, width: 1.5))))
    ]);
  }

  Widget _buildPasswordField({required TextEditingController controller}) {
    final l10n = AppLocalizations.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.password,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
              hintText: l10n.enterPassword,
              filled: true,
              fillColor: AppColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      const BorderSide(color: AppColors.brandBlue, width: 1.5)),
              suffixIcon: IconButton(
                  icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  })))
    ]);
  }
}