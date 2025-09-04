import 'package:Voltgo_User/data/services/vehicles_service.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddVehicleScreen extends StatefulWidget {
  final Function onVehicleAdded;
  const AddVehicleScreen({Key? key, required this.onVehicleAdded})
      : super(key: key);

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

  // ✅ Se agregó la opción 'Otro'
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

  // ✅ Se agregó la opción 'Otro' con un ícono para diferenciarla
  final List<Map<String, dynamic>> _colors = [
    {'name': 'Blanco', 'color': Colors.white},
    {'name': 'Negro', 'color': Colors.black},
    {'name': 'Gris', 'color': Colors.grey},
    {'name': 'Plata', 'color': Colors.grey.shade300},
    {'name': 'Rojo', 'color': Colors.red},
    {'name': 'Azul', 'color': Colors.blue},
    {'name': 'Verde', 'color': Colors.green},
    {'name': 'Otro', 'color': null, 'icon': Icons.add},
  ];

// ✅ MÉTODO: Obtener lista de marcas con localización
  List<Map<String, dynamic>> _getLocalizedBrands(AppLocalizations l10n) {
    final brands = List<Map<String, dynamic>>.from(_popularBrands);
    // Actualizar solo el último elemento que es 'Otro'
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

  String? _selectedBrand;
  String? _selectedConnectorType;
  String? _selectedColor;

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
    // Validar el formulario antes de avanzar
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
      case 0: // Paso 1: Marca, Modelo, Año
        return _makeController.text.trim().isNotEmpty &&
            _modelController.text.trim().isNotEmpty &&
            _yearController.text.trim().isNotEmpty &&
            _isValidYear(_yearController.text.trim());
      case 1: // Paso 2: Placa y Color
        return _plateController.text.trim().isNotEmpty &&
            _selectedColor != null &&
            (_selectedColor != 'Otro' ||
                _colorController.text.trim().isNotEmpty);
      case 2: // Paso 3: Conector
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

  // ✅ Lógica de envío actualizada
  Future<void> _submitVehicle() async {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    if (!_formKey.currentState!.validate()) return;
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    try {
      final String finalColor = (_selectedColor == l10n.other) // ✅ CAMBIAR
          ? _colorController.text.trim()
          : _selectedColor!;

      await VehicleService.addVehicle(
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        plate: _plateController.text.trim(), // Añadido
        color: finalColor, // Añadido
        connectorType: _connectorTypeController.text.trim(),
      );

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.vehicleRegistrationError}: $e', // ✅ CAMBIAR de 'Error al registrar el vehículo: $e'
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

  // ✅ El diálogo ahora llama a onVehicleAdded para la navegación
  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                l10n.vehicleRegistered, // ✅ CAMBIAR de '¡Vehículo Registrado!'
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.vehicleRegisteredSuccess, // ✅ CAMBIAR de 'Tu vehículo ha sido registrado exitosamente.'
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
                    Navigator.of(context).pop(); // Cierra el diálogo
                    widget.onVehicleAdded(); // Llama al callback para navegar
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.continueText, // ✅ CAMBIAR de 'Continuar'
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
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

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
            l10n.registerElectricVehicle, // ✅ CAMBIAR de 'Registra tu Vehículo Eléctrico'
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${l10n.step} ${_currentStep + 1} ${l10n.off} 3', // ✅ CAMBIAR de 'Paso ${_currentStep + 1} de 3'
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

// ✅ CORREGIR _buildStep1() - Agregar listeners para actualizar estado
  Widget _buildStep1() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.vehicleInformation, // ✅ CAMBIAR de 'Información del Vehículo'
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.brand, // ✅ CAMBIAR de 'Marca'
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
              // ✅ USAR MÉTODO LOCALIZADO

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
                        // ✅ CAMBIAR comparación
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
            enabled: _selectedBrand == l10n.other ||
                _selectedBrand == null, // ✅ CAMBIAR comparación
            decoration: InputDecoration(
              hintText: l10n
                  .writeBrandHint, // ✅ CAMBIAR de 'Escribe una marca si no está en la lista'
              filled: true,
              fillColor: (_selectedBrand != l10n.other &&
                      _selectedBrand != null) // ✅ CAMBIAR comparación
                  ? AppColors.gray300.withOpacity(0.3)
                  : AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            // ✅ AGREGAR onChanged para actualizar estado
            onChanged: (value) {
              setState(() {}); // Reactualizar para habilitar/deshabilitar botón
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n
                    .selectOrEnterBrand; // ✅ CAMBIAR de 'Por favor, selecciona o ingresa una marca'
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _modelController,
            label: l10n.model, // ✅ CAMBIAR de 'Modelo'
            hint: l10n.modelHint, // ✅ CAMBIAR de 'Ej: Model 3, Leaf, ID.4'
            icon: Icons.car_rental,
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _yearController,
            label: l10n.year, // ✅ CAMBIAR de 'Año'
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

// ✅ CORREGIR _buildStep2() - Agregar listeners
  Widget _buildStep2() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.identification, // ✅ CAMBIAR de 'Identificación'
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildEnhancedTextField(
            controller: _plateController,
            label: l10n.plate, // ✅ CAMBIAR de 'Placa'
            hint: l10n.plateHint, // ✅ CAMBIAR de 'ABC-123'
            icon: Icons.pin,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.color, // ✅ CAMBIAR de 'Color'
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
            itemCount:
                _getLocalizedColors(l10n).length, // ✅ USAR MÉTODO LOCALIZADO
            itemBuilder: (context, index) {
              final colorData =
                  _getLocalizedColors(l10n)[index]; // ✅ USAR MÉTODO LOCALIZADO
              final isSelected = _selectedColor == colorData['name'];

              // Caso especial para el botón 'Otro'
              if (colorData['name'] == l10n.other) {
                // ✅ CAMBIAR comparación
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
                        color:
                            isSelected ? AppColors.primary : AppColors.gray300,
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
                          l10n.other, // ✅ CAMBIAR de 'Otro'
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

              // Botones de colores normales
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
          // Campo de texto condicional para 'Otro' color
          if (_selectedColor == l10n.other) ...[
            // ✅ CAMBIAR comparación
            const SizedBox(height: 16),
            _buildEnhancedTextField(
              controller: _colorController,
              label: l10n.specifyColor, // ✅ CAMBIAR de 'Especifica el color'
              hint: l10n.colorHint,
              icon: Icons.color_lens_outlined,
              validator: (value) {
                if (_selectedColor == l10n.other && // ✅ CAMBIAR comparación
                    (value == null || value.trim().isEmpty)) {
                  return l10n.enterColor; // ✅ CAMBIAR de 'Ingresa un color'
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
            l10n.technicalSpecs, // ✅ Ahora está envuelto en Text widget
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.connectorType, // ✅ Ahora está envuelto en Text widget
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

// ✅ CORREGIR _buildEnhancedTextField() - Agregar onChanged por defecto
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
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
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
          // ✅ AGREGAR onChanged para actualizar estado
          onChanged: (value) {
            setState(() {}); // Reactualizar para habilitar/deshabilitar botón
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
                  return l10n
                      .fieldRequired; // ✅ CAMBIAR de 'Este campo es requerido'
                }
                if (label == l10n.year) {
                  // ✅ CAMBIAR comparación
                  final year = int.tryParse(value);
                  if (year == null) {
                    return l10n
                        .numbersOnly; // ✅ CAMBIAR de 'Ingresa solo números'
                  }
                  final currentYear = DateTime.now().year;
                  if (year < 1990 || year > currentYear + 1) {
                    return '${l10n.yearRange} 1990 ${l10n.and} ${currentYear + 1}'; // ✅ CAMBIAR mensaje
                  }
                }
                if (label == l10n.plate && value.trim().length < 3) {
                  // ✅ CAMBIAR comparación
                  return l10n
                      .plateMinLength; // ✅ CAMBIAR de 'La placa debe tener al menos 3 caracteres'
                }
                return null;
              },
        ),
      ],
    );
  }

// 8. En _getValidationMessage() - Todos los mensajes de validación:
  String _getValidationMessage() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    switch (_currentStep) {
      case 0:
        if (_makeController.text.trim().isEmpty) {
          return l10n
              .selectBrandMessage; // ✅ CAMBIAR de 'Por favor selecciona una marca'
        }
        if (_modelController.text.trim().isEmpty) {
          return l10n
              .enterModelMessage; // ✅ CAMBIAR de 'Por favor ingresa el modelo'
        }
        if (_yearController.text.trim().isEmpty) {
          return l10n
              .enterYearMessage; // ✅ CAMBIAR de 'Por favor ingresa el año'
        }
        if (!_isValidYear(_yearController.text.trim())) {
          return l10n
              .validYearMessage; // ✅ CAMBIAR de 'Por favor ingresa un año válido'
        }
        break;
      case 1:
        if (_plateController.text.trim().isEmpty) {
          return l10n
              .enterPlateMessage; // ✅ CAMBIAR de 'Por favor ingresa la placa'
        }
        if (_selectedColor == null) {
          return l10n
              .selectColorMessage; // ✅ CAMBIAR de 'Por favor selecciona un color'
        }
        if (_selectedColor == l10n.other &&
            _colorController.text.trim().isEmpty) {
          // ✅ CAMBIAR comparación
          return l10n
              .specifyColorMessage; // ✅ CAMBIAR de 'Por favor especifica el color'
        }
        break;
      case 2:
        if (_selectedConnectorType == null) {
          return l10n
              .selectConnectorMessage; // ✅ CAMBIAR de 'Por favor selecciona el tipo de conector'
        }
        break;
    }
    return l10n
        .completeRequiredFields; // ✅ CAMBIAR de 'Por favor completa todos los campos requeridos'
  }

// ✅ CORREGIR _buildActions() - Cambiar lógica del botón
  Widget _buildActions() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

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
                child: Text(l10n.previous), // ✅ CAMBIAR de 'Anterior'
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              // ✅ CAMBIAR LÓGICA: Solo verificar si está cargando
              onPressed: _isLoading
                  ? null
                  : () {
                      // Validar solo antes de ejecutar la acción
                      if (_validateCurrentStep()) {
                        _nextStep();
                      } else {
                        // Mostrar mensaje si no es válido
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
                              : l10n
                                  .register, // ✅ CAMBIAR de 'Siguiente' y 'Registrar'
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
