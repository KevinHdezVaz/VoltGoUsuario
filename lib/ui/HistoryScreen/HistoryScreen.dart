import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_User/data/services/HistoryService.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/HistoryScreen/ServiceDetailsScreen.dart';
 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<ServiceRequestModel>> _historyFuture;
  String _selectedFilter = 'all';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<ServiceRequestModel> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _historyFuture = HistoryService.fetchHistory();
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

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = HistoryService.fetchHistory();
    });
  }

  // NUEVO MÉTODO: Navegación a detalles
  void _navigateToServiceDetails(ServiceRequestModel serviceRequest) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(
          serviceRequest: serviceRequest,
        ),
      ),
    );
  }

  String _getLocalizedStatus(String status) {
    final l10n = AppLocalizations.of(context);

    switch (status.toLowerCase()) {
      case 'completed':
        return l10n.completed;
      case 'cancelled':
        return l10n.cancelled;
      case 'pending':
        return l10n.pending;
      case 'accepted':
        return l10n.accepted;
      case 'en_route':
        return l10n.enRoute;
      case 'on_site':
        return l10n.onSite;
      case 'charging':
        return l10n.charging;
      default:
        return status;
    }
  }

  void _filterHistory(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  List<ServiceRequestModel> get _filteredList {
    if (_selectedFilter == 'all') {
      return _historyItems;
    }
    return _historyItems.where((item) {
      return item.status.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.serviceHistory,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
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
      body: Container(
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
        child: RefreshIndicator(
          onRefresh: _refreshHistory,
          color: AppColors.primary,
          backgroundColor: AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  l10n.reviewPreviousServices,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _buildFilterChips(),
              Expanded(
                child: FutureBuilder<List<ServiceRequestModel>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    _historyItems = snapshot.data!;
                    final displayedItems = _filteredList;

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: displayedItems.length,
                      itemBuilder: (context, index) {
                        final item = displayedItems[index];
                        return _buildHistoryItem(item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildChip(l10n.all, 'all'),
            const SizedBox(width: 12),
            _buildChip(l10n.completed, 'completed'),
            const SizedBox(width: 12),
            _buildChip(l10n.cancelled, 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String filterValue) {
    final isSelected = _selectedFilter == filterValue;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        _filterHistory(filterValue);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FilterChip(
          label: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
                  isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => _filterHistory(filterValue),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.white,
          checkmarkColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.border.withOpacity(0.5)),
          ),
          elevation: isSelected ? 3 : 1,
          pressElevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ServiceRequestModel item) {
    final l10n = AppLocalizations.of(context);

    IconData icon;
    Color statusColor;

    switch (item.status.toLowerCase()) {
      case 'completed':
        icon = Icons.check_circle;
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        statusColor = AppColors.error;
        break;
      case 'pending':
        icon = Icons.schedule;
        statusColor = AppColors.warning;
        break;
      case 'accepted':
      case 'en_route':
      case 'on_site':
      case 'charging':
        icon = Icons.hourglass_empty;
        statusColor = AppColors.primary;
        break;
      default:
        icon = Icons.help_outline;
        statusColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToServiceDetails(item); // ACTUALIZADO: Navegar a detalles
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(icon, color: statusColor, size: 28),
                ),
                title: Text(
                  _getLocalizedStatus(item.status),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${_formatDateTime(item.acceptedAt ?? item.requestedAt)} • ${_getLocalizedStatus(item.status)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              trailing: const Icon(
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

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${l10n.today} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${l10n.daysAgo}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.errorLoadingHistory}: $error',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              l10n.retry,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_toggle_off,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noServicesInHistory,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // TODO: Navigate to request service screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              l10n.requestService,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}