// ✅ WIDGET PARA BADGE DE NOTIFICACIONES
// Archivo: lib/ui/widgets/NotificationBadge.dart

import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final Offset? offset;
  final bool showZero;

  const NotificationBadge({
    Key? key,
    required this.child,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.offset,
    this.showZero = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showZero && count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0) // Solo mostrar si hay mensajes
          Positioned(
            top: offset?.dy ?? -6,
            right: offset?.dx ?? -6,
            child: Container(
              padding: padding ?? 
                (count > 99 
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                  : const EdgeInsets.all(6)
                ),
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.error,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: GoogleFonts.inter(
                    color: textColor ?? Colors.white,
                    fontSize: fontSize ?? 11,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ✅ WIDGET ESPECÍFICO PARA ICONOS DE CHAT
class ChatBadgeIcon extends StatelessWidget {
  final IconData icon;
  final int unreadCount;
  final VoidCallback? onTap;
  final Color? iconColor;
  final double? iconSize;
  final bool isCircleButton;

  const ChatBadgeIcon({
    Key? key,
    required this.icon,
    required this.unreadCount,
    this.onTap,
    this.iconColor,
    this.iconSize,
    this.isCircleButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widget = NotificationBadge(
      count: unreadCount,
      offset: const Offset(-2, -2),
      child: Icon(
        icon,
        color: iconColor ?? AppColors.textPrimary,
        size: iconSize ?? 18,
      ),
    );

    if (isCircleButton) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(10),
          side: BorderSide(color: iconColor ?? AppColors.info),
        ),
        child: widget,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: widget,
      ),
    );
  }
}

// ✅ BADGE PARA BOTTOM NAVIGATION BAR
class BottomNavBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final bool isSelected;
  final VoidCallback? onTap;

  const BottomNavBadge({
    Key? key,
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.isSelected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NotificationBadge(
              count: badgeCount,
              offset: const Offset(-6, -6),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}