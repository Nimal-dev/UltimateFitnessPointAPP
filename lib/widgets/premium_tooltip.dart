import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PremiumTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const PremiumTooltip({super.key, required this.message, required this.child});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      showDuration: const Duration(seconds: 4),
      waitDuration: const Duration(milliseconds: 200),
      triggerMode: TooltipTriggerMode.tap,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 11,
        color: Colors.white,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      child: child,
    );
  }
}
