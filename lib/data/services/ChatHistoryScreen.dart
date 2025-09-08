// ✅ PANTALLA DE HISTORIAL DE CHATS - CON NOTIFICACIONES INTEGRADAS
// Archivo: lib/ui/chat/ChatHistoryScreen.dart

import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_User/data/services/ChatService.dart';
import 'package:Voltgo_User/data/services/ServiceChatScreen.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/utils/ChatNotificationProvider.dart';
import 'package:Voltgo_User/utils/NotificationBadge.dart'; 
 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen>
    with TickerProviderStateMixin {
  List<ChatHistory> _chatHistory = [];
  bool _isLoading = true;
  String? _error;

  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadChatHistory();
  }

  void _initializeAnimations() {
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _refreshAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await ChatService.getUserChatHistory();
      setState(() {
        _chatHistory = history;
        _isLoading = false;
      });
      
      // ✅ ACTUALIZAR CONTADOR DESPUÉS DE CARGAR
      final chatProvider = Provider.of<ChatNotificationProvider>(context, listen: false);
      chatProvider.forceRefresh();
      
      print('✅ Historial de chats cargado: ${history.length} conversaciones');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Error cargando historial: $e');
    }
  }

  Future<void> _refreshHistory() async {
    HapticFeedback.mediumImpact();
    _refreshController.forward().then((_) {
      _refreshController.reverse();
    });
    await _loadChatHistory();
  }

  void _openChat(ChatHistory chatItem) async {
    HapticFeedback.lightImpact();

    // ✅ MARCAR COMO LEÍDO ANTES DE ABRIR
    final chatProvider = Provider.of<ChatNotificationProvider>(context, listen: false);
    await chatProvider.markAsRead(chatItem.serviceId);

    // Crear ServiceRequestModel básico para el chat
    final serviceRequest = ServiceRequestModel(
      id: chatItem.serviceId,
      userId: 0,
      status: chatItem.serviceStatus,
      requestLat: 0.0,
      requestLng: 0.0,
      requestedAt: DateTime.now(),
      technician: null,
      user: null,
      technicianId: chatItem.otherParticipant?['id'],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceChatScreen(
          serviceRequest: serviceRequest,
          userType: 'user', // Asumir que es usuario en historial
        ),
      ),
    ).then((_) {
      // ✅ RECARGAR AL VOLVER
      _loadChatHistory();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mis Chats',
          style: GoogleFonts.inter(
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
        actions: [
          // ✅ BADGE EN EL BOTÓN DE REFRESH
          Consumer<ChatNotificationProvider>(
            builder: (context, chatProvider, child) {
              return NotificationBadge(
                count: chatProvider.unreadCount,
                child: RotationTransition(
                  turns: _refreshAnimation,
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _refreshHistory,
                    tooltip: 'Actualizar chats',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_chatHistory.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadChatHistory,
      color: AppColors.primary,
      child: Consumer<ChatNotificationProvider>(
        builder: (context, chatProvider, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatHistory.length,
            itemBuilder: (context, index) {
              final chatItem = _chatHistory[index];
              final unreadCount = chatProvider.getUnreadCount(chatItem.serviceId);
              return _buildChatItem(chatItem, unreadCount);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando chats...',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar chats',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadChatHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Intentar nuevamente',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay chats aún',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Los chats con los técnicos aparecerán aquí una vez que tengas servicios activos.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.electric_bolt, size: 20),
              label: Text('Solicitar Servicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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

  // ✅ ACTUALIZADO: Incluir badge de notificaciones
  Widget _buildChatItem(ChatHistory chatItem, int unreadCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: unreadCount > 0 ? 4 : 2, // ✅ Mayor elevación si hay no leídos
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: unreadCount > 0 
              ? BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1)
              : BorderSide.none, // ✅ Borde si hay no leídos
        ),
        child: InkWell(
          onTap: () => _openChat(chatItem),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ✅ AVATAR CON BADGE
                NotificationBadge(
                  count: unreadCount,
                  offset: const Offset(-4, -4),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: unreadCount > 0 
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: unreadCount > 0 
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.3),
                        width: unreadCount > 0 ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        chatItem.otherParticipantName.isNotEmpty
                            ? chatItem.otherParticipantName[0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Información del chat
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      Text(
                        chatItem.otherParticipantName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Último mensaje
                      Text(
                        chatItem.lastMessageText.isNotEmpty 
                            ? chatItem.lastMessageText 
                            : 'Sin mensajes',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: unreadCount > 0 
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Información del servicio
                      Row(
                        children: [
                          Icon(
                            Icons.electric_bolt,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Servicio #${chatItem.serviceId}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          // ✅ INDICADOR DE ESTADO DEL SERVICIO
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(chatItem.serviceStatus).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(chatItem.serviceStatus),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: _getStatusColor(chatItem.serviceStatus),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            chatItem.serviceDate,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ✅ FLECHA CON INDICADOR VISUAL
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: unreadCount > 0 
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: unreadCount > 0 
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODOS AUXILIARES PARA ESTADO DEL SERVICIO
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'en_route':
        return Colors.blue;
      case 'on_site':
        return Colors.purple;
      case 'charging':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'en_route':
        return 'En camino';
      case 'on_site':
        return 'En sitio';
      case 'charging':
        return 'Cargando';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}