// ui/dialogs/improved_plan_selection_dialog.dart
import 'package:Voltgo_User/data/models/StripePlan.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImprovedPlanSelectionDialog extends StatefulWidget {
  final List<StripePlan> plans;

  const ImprovedPlanSelectionDialog({Key? key, required this.plans}) : super(key: key);

  @override
  _ImprovedPlanSelectionDialogState createState() => _ImprovedPlanSelectionDialogState();
}

class _ImprovedPlanSelectionDialogState extends State<ImprovedPlanSelectionDialog> 
    with SingleTickerProviderStateMixin {
  StripePlan? selectedPlan;
  late TabController _tabController;
  List<StripePlan> monthlyPlans = [];
  List<StripePlan> oneTimePlans = [];

  @override
  void initState() {
    super.initState();
    _categorizePlans();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: monthlyPlans.isNotEmpty ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _categorizePlans() {
    for (var plan in widget.plans) {
      if (plan.interval == 'month') {
        monthlyPlans.add(plan);
      } else if (plan.interval == 'one_time') {
        oneTimePlans.add(plan);
      }
    }
    
    // Ordenar por precio
    monthlyPlans.sort((a, b) => a.amount.compareTo(b.amount));
    oneTimePlans.sort((a, b) => a.amount.compareTo(b.amount));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Flexible(child: _buildTabBarView()),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.electric_bolt,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose Your VoltGo Plan',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select the plan that best fits your electric vehicle charging needs',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13, // Reducido de 14 a 13
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 13, // Reducido de 14 a 13
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Agregado para minimizar espacio
              children: [
                Icon(Icons.repeat, size: 16), // Reducido de 18 a 16
                const SizedBox(width: 6), // Reducido de 8 a 6
                Flexible( // Agregado Flexible para prevenir overflow
                  child: Text(
                    'Monthly',
                    overflow: TextOverflow.ellipsis, // Manejo de overflow
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Agregado para minimizar espacio
              children: [
                Icon(Icons.flash_on, size: 16), // Reducido de 18 a 16
                const SizedBox(width: 6), // Reducido de 8 a 6
                Flexible( // Agregado Flexible para prevenir overflow
                  child: Text(
                    'One-Time',
                    overflow: TextOverflow.ellipsis, // Manejo de overflow
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPlansList(monthlyPlans, 'monthly'),
        _buildPlansList(oneTimePlans, 'one_time'),
      ],
    );
  }

  Widget _buildPlansList(List<StripePlan> plans, String planType) {
    if (plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${planType == 'monthly' ? 'monthly' : 'one-time'} plans available',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shrinkWrap: true,
      itemCount: plans.length,
      itemBuilder: (context, index) {
        return _buildEnhancedPlanCard(plans[index], index);
      },
    );
  }

  Widget _buildEnhancedPlanCard(StripePlan plan, int index) {
    final isSelected = selectedPlan?.priceId == plan.priceId;
    final isPopular = _isPopularPlan(plan);
    final isOneTime = plan.interval == 'one_time';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // Carta principal
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? AppColors.primary.withOpacity(0.25)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 12 : 8,
                  offset: Offset(0, isSelected ? 6 : 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => selectedPlan = plan),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con nombre y precio
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.productName,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '\$${plan.amount.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (!isOneTime) ...[
                                      Text(
                                        '/month',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Radio button personalizado
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: isSelected ? AppColors.primary : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Descripción
                      if (plan.productDescription != null) ...[
                        Text(
                          plan.productDescription!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Características destacadas
                      ..._buildPlanFeatures(plan),
                      
                      const SizedBox(height: 16),
                      
                      // Badge inferior
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isOneTime ? Colors.orange.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isOneTime ? Colors.orange.shade300 : Colors.green.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOneTime ? Icons.flash_on : Icons.repeat,
                                  size: 16,
                                  color: isOneTime ? Colors.orange.shade700 : Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOneTime ? 'One-Time Service' : 'Monthly Subscription',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isOneTime ? Colors.orange.shade700 : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (isOneTime)
                            Text(
                              '~25 miles range',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Badge "Popular" o "Recommended"
          if (isPopular)
            Positioned(
              top: -2,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'POPULAR',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPlanFeatures(StripePlan plan) {
    List<String> features = [];
    
    // Características basadas en el nombre del plan
    if (plan.productName.toLowerCase().contains('basic')) {
      features = [
        'Essential roadside coverage',
        '60-minute response time',
        '30% discount on extra services',
        'Basic EV charging support',
      ];
    } else if (plan.productName.toLowerCase().contains('pro')) {
      features = [
        'Priority roadside assistance',
        'Unlimited EV charging discounts',
        'Premium 24/7 support',
        'Advanced service features',
      ];
    } else if (plan.productName.toLowerCase().contains('rescue')) {
      features = [
        'Emergency roadside charging',
        'Up to 20kWh power delivery',
        'Quick service guarantee',
        'No subscription required',
      ];
    } else if (plan.productName.toLowerCase().contains('pass')) {
      features = [
        'Monthly roadside assistance',
        'Pay-as-you-go EV charging',
        'Member discounts',
        'Standard response time',
      ];
    }

    return features.map((feature) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: AppColors.primary,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  bool _isPopularPlan(StripePlan plan) {
    // Lógica para determinar qué plan es popular
    return plan.productName.toLowerCase().contains('pro') ||
           plan.productName.toLowerCase().contains('pass');
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Información de seguridad
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Secure payment powered by Stripe. Cancel anytime.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Maybe Later',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: selectedPlan != null 
                      ? () => Navigator.of(context).pop(selectedPlan)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: selectedPlan != null ? 4 : 0,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Text(
                      selectedPlan != null 
                          ? 'Get ${selectedPlan!.productName}'
                          : 'Select a Plan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}