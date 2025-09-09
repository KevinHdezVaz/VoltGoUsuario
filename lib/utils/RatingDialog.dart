import 'package:Voltgo_User/data/services/RatingService.dart';
import 'package:Voltgo_User/l10n/app_localizations.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 

class RatingDialog extends StatefulWidget {
  final int serviceRequestId;
  final String technicianName;
  final double estimatedPrice;
  final VoidCallback onRatingSubmitted;
  final VoidCallback onSkipped;

  const RatingDialog({
    Key? key,
    required this.serviceRequestId,
    required this.technicianName,
    required this.estimatedPrice,
    required this.onRatingSubmitted,
    required this.onSkipped,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> 
    with SingleTickerProviderStateMixin {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      final success = await RatingService.submitRating(
        widget.serviceRequestId,
        _rating,
        _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      if (success) {
        Navigator.of(context).pop();
        _showSuccess('¡Gracias por tu calificación!');
        widget.onRatingSubmitted();
      } else {
        _showError('Error al enviar la calificación. Intenta de nuevo.');
      }
    } catch (e) {
      _showError('Error de conexión. Verifica tu internet.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

 String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Very bad';
      case 2:
        return 'Bad';
      case 3:
        return 'Regular';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }


  Color _getRatingColor() {
    switch (_rating) {
      case 1:
      case 2:
        return AppColors.error;
      case 3:
        return AppColors.warning;
      case 4:
      case 5:
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de éxito con animación
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
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
                  );
                },
              ),
              const SizedBox(height: 20),
              
              // Título
              Text(
                l10n.serviceCompleted,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
               
               
              // Información del técnico
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        widget.technicianName.isNotEmpty 
                            ? widget.technicianName[0].toUpperCase()
                            : 'T',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.technicianName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Your service technician',
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
              ),
              const SizedBox(height: 24),
              
              // Pregunta de experiencia
              Text(
                l10n.howWasExperience,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Sistema de estrellas con animación
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isSelected = starIndex <= _rating;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = starIndex;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isSelected ? Icons.star : Icons.star_border,
                        color: isSelected ? _getRatingColor() : AppColors.gray300,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              
              // Texto de la calificación
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _getRatingText(),
                  key: ValueKey(_rating),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getRatingColor(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Campo de comentario
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gray300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () {
                        Navigator.of(context).pop();
                        widget.onSkipped();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppColors.gray300),
                      ),
                      child: Text(
                        l10n.skip,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Submit Rating',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar calificaciones en listas
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? totalRatings;
  final double size;
  final bool showNumber;

  const RatingDisplay({
    Key? key,
    required this.rating,
    this.totalRatings,
    this.size = 16,
    this.showNumber = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            IconData iconData;
            Color color;

            if (rating >= starValue) {
              iconData = Icons.star;
              color = AppColors.warning;
            } else if (rating >= starValue - 0.5) {
              iconData = Icons.star_half;
              color = AppColors.warning;
            } else {
              iconData = Icons.star_border;
              color = AppColors.gray300;
            }

            return Icon(
              iconData,
              size: size,
              color: color,
            );
          }),
        ),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.inter(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (totalRatings != null) ...[
            Text(
              ' ($totalRatings)',
              style: GoogleFonts.inter(
                fontSize: size * 0.7,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}