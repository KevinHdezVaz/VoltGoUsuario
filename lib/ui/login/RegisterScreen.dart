import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController =
      TextEditingController(); // Controlador para el número

  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _fullPhoneNumber; // Para guardar LADA + NÚMERO

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;

  // En _RegisterScreenState
  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState); // <-- AÑADE ESTA LÍNEA
    // _companyController.addListener(_updateButtonState); // <-- PUEDES BORRAR ESTA
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

  // En _RegisterScreenState
  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _nameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty && // <-- CAMBIA ESTA LÍNEA
          _passwordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty &&
          (_passwordController.text.trim() ==
              _confirmPasswordController.text.trim());
    });
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

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
            content: Text(l10n
                .welcomeSuccessfulRegistration), // ✅ CAMBIAR de '¡Bienvenido! Registro exitoso.'
            backgroundColor: Colors.green,
          ),
        );
        _navigateAfterAuth(response.user!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.error ??
                  l10n.errorOccurred)), // ✅ CAMBIAR de 'Ocurrió un error'
        );
      }
    } catch (e) {
      // ... manejo de errores existente
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateAfterAuth(UserModel user) {
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
              // Este callback se ejecuta cuando el usuario guarda el vehículo
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
                    _buildForm(),
                    const SizedBox(height: 24),
                    // ▼▼▼ NUEVO: Widget para los botones de login social ▼▼▼
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

  Widget _buildBackground(BuildContext context) {
    return Stack(children: [
      Positioned(
          top: 0,
          right: -90,
          child: Image.asset('assets/images/rectangle1.png',
              width: MediaQuery.of(context).size.width * 0.5,
              color: AppColors.primary, // Color que quieras aplicar
              colorBlendMode:
                  BlendMode.srcIn, // Aplica el color sobre la imagen
              fit: BoxFit.contain)),
    ]);
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

  // ▼▼▼ NUEVO: Helper para crear botones de login social genéricos ▼▼▼
  Widget _buildSocialButton({
    required String assetName,
    required String text,
    required VoidCallback onPressed,
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

// 2. En _buildSocialLogins():
  Widget _buildSocialLogins() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                l10n.or, // ✅ CAMBIAR de 'O'
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
        _buildSocialButton(
          assetName: 'assets/images/gugel.png',
          text: l10n.signUpWithGoogle, // ✅ CAMBIAR de 'Registrarse con Google'
          onPressed: () {
            print('Registro con Google presionado');
          },
        ),
        const SizedBox(height: 12),
        _buildSocialButton(
          assetName: 'assets/images/appell.png',
          text: l10n.signUpWithApple, // ✅ CAMBIAR de 'Registrarse con Apple'
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
          onPressed: () {
            print('Registro con Apple presionado');
          },
        ),
      ],
    );
  }

// 3. En _buildPhoneField():
  Widget _buildPhoneField() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.mobilePhone, // ✅ CAMBIAR de 'Teléfono móvil'
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
            hintText: l10n.phoneNumber, // ✅ CAMBIAR de 'Número de teléfono'
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

// 4. En _buildHeader():
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.createAccount, // ✅ CAMBIAR de 'Crea tu cuenta'
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.completeFormToStart, // ✅ CAMBIAR de 'Completa el formulario para empezar.'
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

// 5. En _buildForm():
  Widget _buildForm() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: l10n.fullName, // ✅ CAMBIAR de 'Nombre completo'
          hint: l10n.yourNameAndSurname, // ✅ CAMBIAR de 'Tu nombre y apellido'
          controller: _nameController,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: l10n.email, // ✅ YA EXISTE
          hint: l10n.emailHint, // ✅ CAMBIAR de 'tucorreo@ejemplo.com'
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildPhoneField(),
        const SizedBox(height: 20),
        _buildPasswordField(
          label: l10n.password, // ✅ YA EXISTE
          controller: _passwordController,
          isPasswordVisible: _isPasswordVisible,
          onToggleVisibility: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          label: l10n.confirmPassword, // ✅ CAMBIAR de 'Confirmar contraseña'
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
              l10n.createAccount, // ✅ CAMBIAR de 'Crear cuenta'
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

// 6. En _buildFooter():
  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.alreadyHaveAccount, // ✅ CAMBIAR de '¿Ya tienes una cuenta? '
          style: TextStyle(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            l10n.signInHere, // ✅ CAMBIAR de 'Inicia sesión.'
            style: TextStyle(
              color: AppColors.brandBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

// 7. En _buildPasswordField() - hint text:
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
  }) {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

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
            hintText:
                l10n.minimumCharacters, // ✅ CAMBIAR de 'Mínimo 8 caracteres'
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
