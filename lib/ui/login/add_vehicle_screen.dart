import 'package:Voltgo_User/data/services/vehicles_service.dart';
import 'package:Voltgo_User/data/models/User/UserVehicle.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddVehicleScreen extends StatefulWidget {
  final Function onVehicleAdded;
  final UserVehicle? vehicleToEdit; // Usar UserVehicle en lugar de Vehicle
  
  const AddVehicleScreen({
    Key? key, 
    required this.onVehicleAdded,
    this.vehicleToEdit,
  }) : super(key: key);

  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  int _currentStep = 0;

  // Controladores para los campos del formulario
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _connectorTypeController = TextEditingController();

  // Listas para los dropdowns y selecciones
  final List<String> _connectorTypes = [
    'Type 1 (J1772)',
    'Type 2 (Mennekes)',
    'CCS Combo 1',
    'CCS Combo 2',
    'CHAdeMO',
    'Tesla Supercharger',
    'GB/T',
  ];

  final List<Map<String, dynamic>> _popularBrands = [
    {'name': 'Tesla', 'icon': '⚡'},
    {'name': 'Nissan', 'icon': '🚗'},
    {'name': 'Chevrolet', 'icon': '🚙'},
    {'name': 'BMW', 'icon': '🏎️'},
    {'name': 'Volkswagen', 'icon': '🚐'},
    {'name': 'Audi', 'icon': '🚘'},
    {'name': 'Ford', 'icon': '🛻'},
    {'name': 'Hyundai', 'icon': '🚕'},
    {'name': 'Otro', 'icon': '➕'},
  ];

  String? _selectedBrand;
  String? _selectedConnectorType;
  String? _selectedColor;

  bool get isEditing => widget.vehicleToEdit != null;

  List<Map<String, dynamic>> _getLocalizedBrands(AppLocalizations l10n) {
    final brands = List<Map<String, dynamic>>.from(_popularBrands);
    brands[brands.length - 1] = {'name': l10n.other, 'icon': '➕'};
    return brands;
  }

  List<Map<String, dynamic>> _getLocalizedColors(AppLocalizations l10n) {
    return [
      {'name': l10n.white, 'color': Colors.white},
      {'name': l10n.black, 'color': Colors.black},
      {'name': l10n.gray, 'color': Colors.grey},
      {'name': l10n.silver, 'color': Colors.grey.shade300},
      {'name': l10n.red, 'color': Colors.red},
      {'name': l10n.blue, 'color': Colors.blue},
      {'name': l10n.green, 'color': Colors.green},
      {'name': l10n.other, 'color': null, 'icon': Icons.add},
    ];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mover la lógica de población de campos aquí donde el contexto está disponible
    if (isEditing) {
      _populateFieldsForEditing();
    }
  }

  void _populateFieldsForEditing() {
    final vehicle = widget.vehicleToEdit!;
    
    _makeController.text = vehicle.make;
    _modelController.text = vehicle.model;
    _yearController.text = vehicle.year.toString();
    _plateController.text = vehicle.plate ?? '';
    _connectorTypeController.text = vehicle.connectorType;

    // Configurar marca seleccionada
    if (_popularBrands.any((brand) => brand['name'] == vehicle.make)) {
      _selectedBrand = vehicle.make;
    } else {
      // Usar string literal en lugar de localización aquí
      _selectedBrand = 'Otro';
    }

    // Configurar color seleccionado - simplificar sin usar localización aquí
    if (vehicle.color != null && vehicle.color!.isNotEmpty) {
      // Lista básica de colores sin localización para la inicialización
      final basicColors = ['Blanco', 'Negro', 'Gris', 'Plata', 'Rojo', 'Azul', 'Verde'];
      if (basicColors.contains(vehicle.color)) {
        _selectedColor = vehicle.color;
        _colorController.text = vehicle.color!;
      } else {
        _selectedColor = 'Otro';
        _colorController.text = vehicle.color!;
      }
    }

    _selectedConnectorType = vehicle.connectorType;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _connectorTypeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitVehicle();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _makeController.text.trim().isNotEmpty &&
            _modelController.text.trim().isNotEmpty &&
            _yearController.text.trim().isNotEmpty &&
            _isValidYear(_yearController.text.trim());
      case 1:
        return _plateController.text.trim().isNotEmpty &&
            _selectedColor != null &&
            (_selectedColor != 'Otro' ||
                _colorController.text.trim().isNotEmpty);
      case 2:
        return _selectedConnectorType != null;
      default:
        return false;
    }
  }

  bool _isValidYear(String yearText) {
    final year = int.tryParse(yearText);
    if (year == null) return false;
    final currentYear = DateTime.now().year;
    return year >= 1990 && year <= currentYear + 1;
  }

  Future<void> _submitVehicle() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    try {
      final String finalColor = (_selectedColor == l10n.other)
          ? _colorController.text.trim()
          : _selectedColor!;

      if (isEditing) {
        // Usar el método existente updateUserVehicle
        await VehicleService.updateUserVehicle(
          vehicleId: widget.vehicleToEdit!.id,
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          year: int.parse(_yearController.text.trim()),
          plate: _plateController.text.trim(),
          color: finalColor,
          connectorType: _connectorTypeController.text.trim(),
        );
      } else {
        // Usar el método existente addVehicle
        await VehicleService.addVehicle(
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          year: int.parse(_yearController.text.trim()),
          plate: _plateController.text.trim(),
          color: finalColor,
          connectorType: _connectorTypeController.text.trim(),
        );
      }

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing 
                ? '${l10n.vehicleUpdateError}: $e'
                : '${l10n.vehicleRegistrationError}: $e',
            style: TextStyle(color: AppColors.textOnPrimary),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEditing 
                    ? l10n.vehicleUpdated
                    : l10n.vehicleRegistered,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isEditing 
                    ? l10n.vehicleUpdatedSuccess
                    : l10n.vehicleRegisteredSuccess,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onVehicleAdded();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.continueText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                    ],
                  ),
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.brandBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.electric_car,
              color: AppColors.accent,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isEditing 
                ? l10n.editElectricVehicle
                : l10n.registerElectricVehicle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${l10n.step} ${_currentStep + 1} ${l10n.off} 3',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppColors.primary
                    : AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.vehicleInformation,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.brand,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getLocalizedBrands(l10n).map((brand) {
              final isSelected = _selectedBrand == brand['name'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(brand['icon']),
                    const SizedBox(width: 4),
                    Text(brand['name']),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedBrand = brand['name'];
                      if (_selectedBrand == l10n.other) {
                        _makeController.clear();
                      } else {
                        _makeController.text = _selectedBrand!;
                      }
                    }
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _makeController,
            enabled: _selectedBrand == l10n.other || _selectedBrand == null,
            decoration: InputDecoration(
              hintText: l10n.writeBrandHint,
              filled: true,
              fillColor: (_selectedBrand != l10n.other && _selectedBrand != null)
                  ? AppColors.gray300.withOpacity(0.3)
                  : AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.selectOrEnterBrand;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _modelController,
            label: l10n.model,
            hint: l10n.modelHint,
            icon: Icons.car_rental,
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _yearController,
            label: l10n.year,
            hint: DateTime.now().year.toString(),
            icon: Icons.calendar_today,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.identification,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildEnhancedTextField(
            controller: _plateController,
            label: l10n.plate,
            hint: l10n.plateHint,
            icon: Icons.pin,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.color,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _getLocalizedColors(l10n).length,
            itemBuilder: (context, index) {
              final colorData = _getLocalizedColors(l10n)[index];
              final isSelected = _selectedColor == colorData['name'];

              if (colorData['name'] == l10n.other) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorData['name'];
                      _colorController.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.gray300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          colorData['icon'],
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.other,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = colorData['name'];
                    _colorController.text = colorData['name'];
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorData['color'],
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gray300),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        colorData['name'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_selectedColor == l10n.other) ...[
            const SizedBox(height: 16),
            _buildEnhancedTextField(
              controller: _colorController,
              label: l10n.specifyColor,
              hint: l10n.colorHint,
              icon: Icons.color_lens_outlined,
              validator: (value) {
                if (_selectedColor == l10n.other &&
                    (value == null || value.trim().isEmpty)) {
                  return l10n.enterColor;
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.technicalSpecs,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.connectorType,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...(_connectorTypes.map((type) {
            final isSelected = _selectedConnectorType == type;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedConnectorType = type;
                    _connectorTypeController.text = type;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.electrical_services),
                      const SizedBox(width: 12),
                      Expanded(child: Text(type)),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
          validator: validator ??
              (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.fieldRequired;
                }
                if (label == l10n.year) {
                  final year = int.tryParse(value);
                  if (year == null) {
                    return l10n.numbersOnly;
                  }
                  final currentYear = DateTime.now().year;
                  if (year < 1990 || year > currentYear + 1) {
                    return '${l10n.yearRange} 1990 ${l10n.and} ${currentYear + 1}';
                  }
                }
                if (label == l10n.plate && value.trim().length < 3) {
                  return l10n.plateMinLength;
                }
                return null;
              },
        ),
      ],
    );
  }

  String _getValidationMessage() {
    final l10n = AppLocalizations.of(context);

    switch (_currentStep) {
      case 0:
        if (_makeController.text.trim().isEmpty) {
          return l10n.selectBrandMessage;
        }
        if (_modelController.text.trim().isEmpty) {
          return l10n.enterModelMessage;
        }
        if (_yearController.text.trim().isEmpty) {
          return l10n.enterYearMessage;
        }
        if (!_isValidYear(_yearController.text.trim())) {
          return l10n.validYearMessage;
        }
        break;
      case 1:
        if (_plateController.text.trim().isEmpty) {
          return l10n.enterPlateMessage;
        }
        if (_selectedColor == null) {
          return l10n.selectColorMessage;
        }
        if (_selectedColor == l10n.other &&
            _colorController.text.trim().isEmpty) {
          return l10n.specifyColorMessage;
        }
        break;
      case 2:
        if (_selectedConnectorType == null) {
          return l10n.selectConnectorMessage;
        }
        break;
    }
    return l10n.completeRequiredFields;
  }

  Widget _buildActions() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.gray300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.previous),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_validateCurrentStep()) {
                        _nextStep();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_getValidationMessage()),
                            backgroundColor: AppColors.warning,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep < 2
                              ? l10n.next
                              : (isEditing ? l10n.updateVehicle : l10n.register),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep < 2 ? Icons.arrow_forward : Icons.check,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}