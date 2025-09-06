import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:Voltgo_User/data/services/ProfileCompletionService.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/login/add_vehicle_screen.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:Voltgo_User/data/services/auth_api_service.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/utils/AnimatedTruckProgress.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:math' as math;

class CompleteProfileScreen extends StatefulWidget {
  final UserModel user;
  final String token;

  const CompleteProfileScreen({
    Key? key,
    required this.user,
    required this.token,
  }) : super(key: key);

  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  String? _fullPhoneNumber;
  
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;

 
 @override
void initState() {
  super.initState();
  _phoneController.addListener(_updateButtonState);
  _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  
  // ✅ DEBUGGING TEMPORAL
  _debugTokenInCompleteProfile();
}

void _debugTokenInCompleteProfile() async {
  print('🔍 === CompleteProfileScreen DEBUG ===');
  final hasToken = await TokenStorage.hasToken();
  final token = await TokenStorage.getToken();
  print('🔍 CompleteProfile - hasToken: $hasToken');
  print('🔍 CompleteProfile - token presente: ${token != null}');
  if (token != null) {
    print('🔍 CompleteProfile - token (20 chars): ${token.substring(0, math.min(20, token.length))}...');
  }
  print('🔍 CompleteProfile - Token del widget: ${widget.token.substring(0, math.min(20, widget.token.length))}...');
}

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _phoneController.text.trim().isNotEmpty;
    });
  }

// En tu CompleteProfileScreen, actualiza el método _completeProfile:

 Future<void> _completeProfile() async {
  final l10n = AppLocalizations.of(context);

  if (!_isButtonEnabled || _isLoading) return;
  
  // ✅ DEBUGGING ANTES DE EMPEZAR
  print('🔍 === _completeProfile DEBUG INICIO ===');
  final hasTokenBefore = await TokenStorage.hasToken();
  final tokenBefore = await TokenStorage.getToken();
  print('🔍 _completeProfile - hasToken ANTES: $hasTokenBefore');
  print('🔍 _completeProfile - token ANTES: ${tokenBefore != null ? "presente" : "null"}');
  print('🔍 _completeProfile - Widget token: ${widget.token.substring(0, math.min(20, widget.token.length))}...');
  
  // ✅ VERIFICAR SI EL TOKEN DEL WIDGET COINCIDE CON EL ALMACENADO
  if (tokenBefore != widget.token) {
    print('🚨 ¡TOKEN DEL WIDGET NO COINCIDE CON EL ALMACENADO!');
    print('🚨 Widget token: ${widget.token.substring(0, 20)}...');
    print('🚨 Stored token: ${tokenBefore?.substring(0, 20) ?? "null"}...');
    
    // ✅ INTENTAR RESTAURAR EL TOKEN DEL WIDGET
    print('🔧 Intentando restaurar token del widget...');
    await TokenStorage.saveToken(widget.token);
    
    final restoredToken = await TokenStorage.getToken();
    print('🔧 Token restaurado: ${restoredToken != null ? "✅ exitoso" : "❌ falló"}');
  }

  setState(() => _isLoading = true);
  _animationController.repeat();

  try {
    // ✅ DEBUGGING JUSTO ANTES DE LA LLAMADA AL SERVICIO
    final tokenJustBefore = await TokenStorage.getToken();
    print('🔍 Token JUSTO antes de updateUserProfile: ${tokenJustBefore != null ? "presente" : "null"}');
    
    final response = await AuthService.updateUserProfile(
      phone: _fullPhoneNumber,
    );

    _animationController.stop();
    if (!mounted) return;

    if (response.success && response.user != null) {
      // ✅ LIMPIAR FLAG DE PERFIL EN PROGRESO
      await ProfileCompletionService.clearProfileInProgress();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileCompleted),
          backgroundColor: Colors.green,
        ),
      );
      _navigateAfterAuth(response.user!);
    } else {
      print('❌ Error en updateUserProfile: ${response.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? l10n.errorOccurred),
        ),
      );
    }
  } catch (e) {
    print('❌ Exception en _completeProfile: $e');
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

// Y también en el método _skipPhoneNumber:
void _skipPhoneNumber() {
  // ✅ LIMPIAR FLAG ANTES DE NAVEGAR
  ProfileCompletionService.clearProfileInProgress().then((_) {
    _navigateAfterAuth(widget.user);
  });
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
                    const SizedBox(height: 40),
                    _buildUserInfo(),
                    const SizedBox(height: 30),
                    _buildForm(),
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
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: -90,
          child: Image.asset(
            'assets/images/rectangle1.png',
            width: MediaQuery.of(context).size.width * 0.5,
            color: AppColors.primary,
            colorBlendMode: BlendMode.srcIn,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono de usuario o check
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.person_add,
              size: 40,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.completeYourProfile,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addPhoneToCompleteRegistration,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.registeredData,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(l10n.fullName, widget.user.name),
          const SizedBox(height: 8),
          _buildInfoRow(l10n.email, widget.user.email),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhoneField(),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isButtonEnabled && !_isLoading ? _completeProfile : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonEnabled && !_isLoading
                  ? AppColors.brandBlue
                  : AppColors.gray300,
              disabledBackgroundColor: AppColors.gray300,
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0,
            ),
            child: Text(
              l10n.completeProfile,
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

  Widget _buildPhoneField() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.mobilePhone,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "*",
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ],
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
              borderSide: const BorderSide(
                color: AppColors.brandBlue,
                width: 1.5,
              ),
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
        const SizedBox(height: 8),
        Text(
          l10n.phoneNumberWillBeUsedFor,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

   
}