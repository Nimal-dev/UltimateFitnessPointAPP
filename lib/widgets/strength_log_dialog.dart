import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StrengthLogDialog extends StatefulWidget {
  const StrengthLogDialog({super.key});

  @override
  State<StrengthLogDialog> createState() => _StrengthLogDialogState();
}

class _StrengthLogDialogState extends State<StrengthLogDialog> {
  String _selectedExercise = "Bench Press";
  final _weightController = TextEditingController();
  final List<String> _exercises = [
    "Bench Press",
    "Squat",
    "Deadlift",
    "Overhead Press"
  ];

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'NEW STRENGTH LOG',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXERCISE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedExercise,
                dropdownColor: AppTheme.cardBackground,
                isExpanded: true,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                items: _exercises.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedExercise = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'WEIGHT (KG)',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'e.g. 100.0',
              hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.accent),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final weight = double.tryParse(_weightController.text) ?? 0.0;
            if (weight > 0) {
              Navigator.pop(context, {
                'exercise': _selectedExercise,
                'weight': weight,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'SAVE LOG',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
