import 'package:Voltgo_User/data/models/User/UserVehicle.dart';
import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:Voltgo_User/data/services/ChatHistoryScreen.dart';
import 'package:Voltgo_User/data/services/auth_api_service.dart';
import 'package:Voltgo_User/data/services/vehicles_service.dart';
 import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/ui/login/LoginScreen.dart';
import 'package:Voltgo_User/ui/login/add_vehicle_screen.dart';
import 'package:Voltgo_User/ui/profile/EditProfileScreen.dart';
import 'package:Voltgo_User/ui/profile/PrivacyPolicyScreen.dart';
import 'package:Voltgo_User/ui/profile/TermsAndConditionsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  late Future<UserModel?> _userFuture;
  bool _darkModeEnabled = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // ✅ NUEVA VARIABLE: Para controlar el estado de logout
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _userFuture = AuthService.fetchUserProfile();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ✅ MÉTODO MEJORADO: Logout con indicador de carga
  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context);
    final shouldLogout = await _showLogoutConfirmationDialog();
    if (!shouldLogout) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      HapticFeedback.mediumImpact();

      // Simular un pequeño delay para mostrar el indicador
      await Future.delayed(const Duration(milliseconds: 500));

      // Realizar el logout
      await AuthService.logout();

      if (mounted) {
        // Pequeño delay adicional para suavizar la transición
        await Future.delayed(const Duration(milliseconds: 300));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Manejar errores de logout
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.logoutError, // ✅ CAMBIAR de 'Error al cerrar sesión. Inténtalo nuevamente.'

                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ NUEVO MÉTODO: Diálogo de confirmación
  Future<bool> _showLogoutConfirmationDialog() async {
    final l10n = AppLocalizations.of(context);

    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: AppColors.warning,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.logout, // ✅ CAMBIAR de 'Cerrar Sesión'
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                l10n.logoutConfirmationMessage, // ✅ CAMBIAR de '¿Estás seguro de que quieres cerrar sesión?'
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    l10n.cancel, // ✅ YA EXISTE
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    l10n.logout, // ✅ CAMBIAR de 'Cerrar Sesión'
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ✅ WIDGET MEJORADO: Botón de logout con indicador de carga
  Widget _buildLogoutButton() {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTapDown: _isLoggingOut ? null : (_) => _animationController.forward(),
      onTapUp: _isLoggingOut ? null : (_) => _animationController.reverse(),
      onTapCancel: _isLoggingOut ? null : () => _animationController.reverse(),
      onTap: _isLoggingOut ? null : _handleLogout,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          elevation: 3,
          shadowColor: AppColors.error.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: _isLoggingOut
                    ? AppColors.error.withOpacity(0.05)
                    : AppColors.error.withOpacity(0.1),
                border: Border.all(
                  color: _isLoggingOut
                      ? AppColors.error.withOpacity(0.2)
                      : AppColors.error.withOpacity(0.3),
                ),
              ),
              child: ListTile(
                enabled: !_isLoggingOut,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 8,
                ),
                leading: _isLoggingOut
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.error.withOpacity(0.7),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.logout,
                        color: AppColors.error,
                        size: 28,
                      ),
                title: Text(
                  _isLoggingOut
                      ? l10n.loggingOut
                      : l10n
                          .logout, // ✅ CAMBIAR de 'Cerrando Sesión...' y 'Cerrar Sesión'
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isLoggingOut
                        ? AppColors.error.withOpacity(0.7)
                        : AppColors.error,
                  ),
                ),
                // ✅ OPCIONAL: Agregar texto adicional cuando está cargando
                subtitle: _isLoggingOut
                    ? Text(
                        l10n.pleaseWait, // ✅ CAMBIAR de 'Por favor espera...'
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ALTERNATIVA: Overlay de carga global (opcional)
  Widget _buildLoadingOverlay() {
    final l10n = AppLocalizations.of(context);

    if (!_isLoggingOut) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.loggingOut, // ✅ CAMBIAR de 'Cerrando sesión...'
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pleaseWaitMoment, // ✅ CAMBIAR de 'Por favor espera un momento'
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



void _handleEditVehicle() async {
  final l10n = AppLocalizations.of(context);
  
  try {
    // Obtener vehículos del usuario
    final vehicles = await VehicleService.getUserVehicles();
    
    if (vehicles.isEmpty) {
      // Si no tiene vehículos, mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dont have vehicles to edit'), // Puedes cambiar el mensaje si es necesario
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Como solo tiene 1 vehículo, tomar el primero y editarlo
      final vehicle = vehicles.first;
      _navigateToEditVehicle(vehicle);
    }
  } catch (e) {
    // Mostrar error si no se pueden cargar los vehículos
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading vehicles'), // Puedes cambiar el mensaje si es necesario
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
 
 void _navigateToEditVehicle(UserVehicle vehicle) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddVehicleScreen(
        vehicleToEdit: vehicle,
        onVehicleAdded: () {
          Navigator.pop(context);
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).vehicleUpdatedSuccess ?? 'Vehículo actualizado exitosamente'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.settings, // ✅ CAMBIAR de 'Ajustes'
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppColors.textOnPrimary,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.brandBlue.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: AppColors.gray300.withOpacity(0.4),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.background,
                  AppColors.lightGrey.withOpacity(0.5)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0)
                      .copyWith(bottom: 130.0),
              children: [
                FutureBuilder<UserModel?>(
                  future: _userFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return _buildProfileHeader(
                          name: l10n.error, // ✅ CAMBIAR de 'Error'
                          email: l10n.couldNotLoadProfile); //
                    }
                    final user = snapshot.data!;
                    return _buildProfileHeader(
                        name: user.name, email: user.email);
                  },
                ),
                const SizedBox(height: 24),

                // Account Section
                _buildSectionHeader(l10n.account), // ✅ CAMBIAR de 'Cuenta'
                // En tu SettingsScreen, reemplaza la sección del botón "Editar Perfil":

                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: l10n.editProfile,
                  onTap: () async {
                    // Cargar el usuario actual antes de navegar
                    final user = await AuthService.fetchUserProfile();
                    if (user != null && mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(user: user),
                        ),
                      );

                      // Si se actualizó el perfil, recargar datos
                      if (result == true) {
                        setState(() {
                          _userFuture = AuthService.fetchUserProfile();
                        });
                      }
                    } else {
                      // Si no se puede cargar el usuario, mostrar error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.couldNotLoadProfile),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.chat_bubble_outline,
                  title: l10n.chatHistory, // ✅ CAMBIAR de 'Historial de Chats'
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatHistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.paymentMethods,
                  onTap: () {},
                ),

                const Divider(height: 32, color: AppColors.gray300),

                // Vehicle Section
                _buildSectionHeader(l10n.vehicle),
               _buildSettingsItem(
  icon: Icons.directions_car_outlined,
  title: l10n.manageVehicles ?? 'Editar Vehículo', // Singular porque es solo 1
  onTap: _handleEditVehicle, // Método simplificado
),

                const Divider(height: 32, color: AppColors.gray300),
                // Vehicle Section
                _buildSectionHeader(l10n.otros),
                _buildSettingsItem(
                  icon: Icons.bookmark_outline,
                  title: l10n.tyc,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsAndConditionsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.politicadeprivacidad, // ✅ CAMBIAR de 'Documentos'
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),

                const Divider(height: 32, color: AppColors.gray300),
                const SizedBox(height: 24),

                // ✅ BOTÓN MEJORADO: Logout Button
                _buildLogoutButton(),
              ],
            ),
          ),

          // ✅ OPCIONAL: Overlay de carga global
          // _buildLoadingOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoggingOut
            ? null
            : () {
                HapticFeedback.lightImpact();
              },
        backgroundColor: _isLoggingOut ? AppColors.disabled : AppColors.accent,
        child: Icon(
          Icons.edit,
          color:
              _isLoggingOut ? AppColors.textSecondary : AppColors.textOnPrimary,
        ),
        elevation: 4,
        tooltip: l10n.editProfile, // ✅ CAMBIAR de 'Editar Perfil'
      ),
    );
  }

  Widget _buildProfileHeader({required String name, required String email}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.lightGrey, AppColors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child:
                  Icon(Icons.person, size: 32, color: AppColors.textOnPrimary),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, // Usa el nombre del parámetro
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email, // Usa el email del parámetro
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shadowColor: AppColors.gray300.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Icon(icon, color: AppColors.brandBlue, size: 28),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shadowColor: AppColors.gray300.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            secondary: Icon(icon, color: AppColors.brandBlue, size: 28),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            value: value,
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
            activeColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withOpacity(0.5),
            inactiveThumbColor: AppColors.disabled,
            inactiveTrackColor: AppColors.lightGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }
}
