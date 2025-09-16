// lib/ui/subscription/CurrentSubscriptionScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Voltgo_User/data/models/UserSubscription.dart';
import 'package:Voltgo_User/data/services/SubscriptionService.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';

class CurrentSubscriptionScreen extends StatefulWidget {
  const CurrentSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<CurrentSubscriptionScreen> createState() => _CurrentSubscriptionScreenState();
}

class _CurrentSubscriptionScreenState extends State<CurrentSubscriptionScreen> {
  UserSubscription? _subscription;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subscription = await SubscriptionService.getCurrentSubscription();
      setState(() {
        _subscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Subscription',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.brandBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSubscription,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.background,
            ],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading subscription...',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_subscription == null) {
      return _buildNoSubscriptionState();
    }

    return _buildSubscriptionDetails();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error loading subscription',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error occurred',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSubscription,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.card_membership,
                color: AppColors.warning,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Subscription',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You don\'t have an active subscription. Purchase a plan to access our services.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to plan selection
                Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Browse Plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubscriptionCard(),
          const SizedBox(height: 24),
          _buildUsageCard(),
          const SizedBox(height: 24),
          _buildDetailsCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final isActive = _subscription!.isActive;
    final planColor = _subscription!.planType == 'monthly' ? AppColors.primary : AppColors.success;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              planColor.withOpacity(0.1),
              planColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: planColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _subscription!.planName!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: planColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.electric_bolt,
                  color: planColor,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _subscription!.planType == 'monthly' ? 'Monthly Subscription' : 'One-Time Plan',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTimeRemaining(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRemaining() {
    if (_subscription!.planType == 'one_time') {
      final remainingServices = _subscription!.remainingServices ?? 0;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.confirmation_number, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Services Remaining',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$remainingServices services',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: remainingServices > 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Monthly subscription
      final now = DateTime.now();
      final expiresAt = _subscription!.expiresAt;
      final daysRemaining = expiresAt?.difference(now).inDays ?? 0;

      Color timeColor = AppColors.success;
      if (daysRemaining <= 3) timeColor = AppColors.error;
      else if (daysRemaining <= 7) timeColor = AppColors.warning;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: timeColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Remaining',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    daysRemaining > 0 ? '$daysRemaining days' : 'Expired',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: timeColor,
                    ),
                  ),
                  if (expiresAt != null)
                    Text(
                      'Expires: ${_formatDate(expiresAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildUsageCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Usage Statistics',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_subscription!.planType == 'one_time') ...[
              _buildUsageRow(
                'Total Services',
                '${_subscription!.totalServices ?? 0}',
                Icons.electric_bolt,
                AppColors.primary,
              ),
              const SizedBox(height: 12),
              _buildUsageRow(
                'Services Used',
                '${(_subscription!.totalServices ?? 0) - (_subscription!.remainingServices ?? 0)}',
                Icons.done,
                AppColors.success,
              ),
              const SizedBox(height: 12),
              _buildUsageRow(
                'Remaining',
                '${_subscription!.remainingServices ?? 0}',
                Icons.pending,
                AppColors.warning,
              ),
            ] else ...[
              _buildUsageRow(
                'Services This Month',
                '${_subscription!.servicesUsedThisMonth ?? 0}',
                Icons.electric_bolt,
                AppColors.primary,
              ),
              const SizedBox(height: 12),
              _buildUsageRow(
                'Plan Type',
                'Unlimited Services',
                Icons.all_inclusive,
                AppColors.success,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Subscription Details',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Plan ID', _subscription!.subscriptionId ?? 'N/A'),
            const SizedBox(height: 12),
            _buildDetailRow('Status', _subscription!.isActive ? 'Active' : 'Inactive'),
            const SizedBox(height: 12),
            _buildDetailRow('Created', _formatDate(_subscription!.createdAt)),
            if (_subscription!.expiresAt != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Expires', _formatDate(_subscription!.expiresAt!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_subscription!.planType == 'monthly' && _subscription!.isActive) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showCancelConfirmation();
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Subscription'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!_subscription!.isActive || 
            (_subscription!.planType == 'one_time' && (_subscription!.remainingServices ?? 0) <= 0)) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Browse New Plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancel Subscription'),
          content: const Text(
            'Are you sure you want to cancel your subscription? You will lose access to unlimited services at the end of your current billing period.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Subscription'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement cancellation logic
                _showSnackbar('Subscription cancellation requested', AppColors.warning);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}