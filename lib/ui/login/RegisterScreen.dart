import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:Voltgo_User/data/services/GoogleService.dart'; // ✅ AGREGAR IMPORT
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/login/CompleteProfileScreen.dart';
import 'package:Voltgo_User/ui/login/add_vehicle_screen.dart';
 import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:Voltgo_User/data/services/auth_api_service.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/ui/login/LoginScreen.dart';
import 'package:Voltgo_User/utils/AnimatedTruckProgress.dart';
import 'package:Voltgo_User/utils/encryption_utils.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:developer' as developer; // ✅ AGREGAR IMPORT

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _fullPhoneNumber;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _nameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty &&
          (_passwordController.text.trim() ==
              _confirmPasswordController.text.trim());
    });
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);

    if (!_isButtonEnabled || _isLoading) return;
    setState(() => _isLoading = true);
    _animationController.repeat();

    try {
      final response = await AuthService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _fullPhoneNumber,
        userType: 'user',
      );

      _animationController.stop();
      if (!mounted) return;

      if (response.success && response.token != null && response.user != null) {
        await TokenStorage.saveToken(response.token!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.welcomeSuccessfulRegistration),
            backgroundColor: Colors.green,
          ),
        );
        _navigateAfterAuth(response.user!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.error ?? l10n.errorOccurred)),
        );
      }
    } catch (e) {
      _animationController.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ NUEVO: Método para Google Sign Up con navegación a CompleteProfile
  Future<void> _signUpWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _animationController.repeat();

    try {
      developer.log('Iniciando Google Sign Up...');
      
      final result = await GoogleAuthService.signInWithGoogle();
      
      _animationController.stop();
      if (!mounted) return;

      if (result.success && result.user != null && result.token != null) {
        developer.log('Google Sign Up exitoso');
        
        // Crear modelo de usuario desde la respuesta
        final userMap = result.user!;
        final userModel = UserModel.fromJson(userMap);
        
        // ✅ VERIFICAR SI NECESITA COMPLETAR PERFIL
        final phone = userMap['phone'];
        
        if (phone == null || phone.toString().trim().isEmpty) {
          developer.log('Usuario necesita completar perfil - redirigiendo a CompleteProfileScreen');
          
          // Usuario necesita completar su perfil (agregar teléfono)
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
          
          // Usuario ya tiene toda la información necesaria
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.welcomeSuccessfulRegistration),
              backgroundColor: Colors.green,
            ),
          );
          
          _navigateAfterAuth(userModel);
        }
      } else {
        // Error en Google Sign Up
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? l10n.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _animationController.stop();
      developer.log('Excepción en Google Sign Up: $e');
      
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

  void _navigateAfterAuth(UserModel user) {
    if (user.hasRegisteredVehicle) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
        (route) => false,
      );
    } else {
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
                    const SizedBox(height: 60),
                    _buildHeader(),
                    const SizedBox(height: 30),
                    // ✅ MOVIDO: Botones sociales arriba
                    _buildSocialLogins(),
                    const SizedBox(height: 30),
                    // ✅ NUEVO: Separador con texto
                    _buildSeparator(),
                    const SizedBox(height: 30),
                    // ✅ MOVIDO: Formulario de registro por email abajo
                    _buildForm(),
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

  Widget _buildBackground(BuildContext context) {
    return Stack(children: [
      Positioned(
          top: 0,
          right: -90,
          child: Image.asset('assets/images/rectangle1.png',
              width: MediaQuery.of(context).size.width * 0.5,
              color: AppColors.primary,
              colorBlendMode: BlendMode.srcIn,
              fit: BoxFit.contain)),
    ]);
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.createAccount,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.completeFormToStart,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ACTUALIZADO: Botones sociales con Google funcional
  Widget _buildSocialLogins() {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // ✅ Botón de Google - FUNCIONAL
        _buildSocialButton(
          assetName: 'assets/images/gugel.png',
          text: l10n.signUpWithGoogle,
          onPressed: _isLoading ? null : _signUpWithGoogle, // ← Conectar aquí
        ),
        const SizedBox(height: 12),
        _buildSocialButton(
          assetName: 'assets/images/appell.png',
          text: l10n.signUpWithApple,
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
          onPressed: _isLoading ? null : () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Apple Sign Up próximamente'),
              ),
            );
          },
        ),
      ],
    );
  }

  // ✅ NUEVO: Separador entre botones sociales y formulario
  Widget _buildSeparator() {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            l10n.orRegisterWithEmail, // ✅ Agregar esta clave de localización
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButton({
    required String assetName,
    required String text,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Image.asset(assetName, height: 22, width: 22),
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

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: l10n.fullName,
          hint: l10n.yourNameAndSurname,
          controller: _nameController,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: l10n.email,
          hint: l10n.emailHint,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildPhoneField(),
        const SizedBox(height: 20),
        _buildPasswordField(
          label: l10n.password,
          controller: _passwordController,
          isPasswordVisible: _isPasswordVisible,
          onToggleVisibility: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          label: l10n.confirmPassword,
          controller: _confirmPasswordController,
          isPasswordVisible: _isConfirmPasswordVisible,
          onToggleVisibility: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isButtonEnabled && !_isLoading ? _register : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonEnabled && !_isLoading
                  ? AppColors.brandBlue
                  : AppColors.gray300,
              disabledBackgroundColor: AppColors.gray300,
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              elevation: 0,
            ),
            child: Text(
              l10n.createAccount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.alreadyHaveAccount,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            l10n.signInHere,
            style: TextStyle(
              color: AppColors.brandBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      {required String label,
      required String hint,
      required TextEditingController controller,
      TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          keyboardType: keyboardType,
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

  Widget _buildPhoneField() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.mobilePhone,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        IntlPhoneField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: l10n.phoneNumber,
            filled: true,
            fillColor: AppColors.lightGrey.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
                  const BorderSide(color: AppColors.brandBlue, width: 1.5),
            ),
          ),
          initialCountryCode: 'MX',
          onChanged: (phone) {
            setState(() {
              _fullPhoneNumber = phone.completeNumber;
            });
            _updateButtonState();
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
  }) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            hintText: l10n.minimumCharacters,
            filled: true,
            fillColor: AppColors.lightGrey.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
                  const BorderSide(color: AppColors.brandBlue, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}