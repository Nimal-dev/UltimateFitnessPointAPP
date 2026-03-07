import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/member_provider.dart';
import '../providers/diet_provider.dart';
import '../theme/app_theme.dart';

class WaterTrackerCard extends StatelessWidget {
  const WaterTrackerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MemberProvider, DietProvider>(
      builder: (context, memberProvider, dietProvider, child) {
        final consumed = dietProvider.log?.waterIntake ?? 0;
        final goal = memberProvider.userData?.dailyWaterGoal ?? 8;
        final progress = (consumed / goal).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.water_drop_rounded, 
                          color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Hydration',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => dietProvider.setWater(consumed + 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.black, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Log Water',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$consumed / $goal Glasses',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
