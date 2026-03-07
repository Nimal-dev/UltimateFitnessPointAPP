import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/member_model.dart';
import '../../models/analytics_model.dart';
import '../../widgets/custom_empty_state_widget.dart';
import '../../widgets/premium_tooltip.dart';
import 'trainer_detail_screen.dart';

class OwnerTrainersScreen extends StatefulWidget {
  const OwnerTrainersScreen({super.key});

  @override
  State<OwnerTrainersScreen> createState() => _OwnerTrainersScreenState();
}

class _OwnerTrainersScreenState extends State<OwnerTrainersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchMembers();
      context.read<OwnerProvider>().fetchStaffStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OwnerProvider>();
    final trainers = p.members.where((m) => m.role == 'Trainer').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
            children: const [
              TextSpan(text: 'STAFF ', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'MANAGEMENT', style: TextStyle(color: AppTheme.blue)),
            ],
          ),
        ),
        actions: [
          PremiumTooltip(
            message: 'Refresh staff performance metrics',
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.blue),
              onPressed: () {
                p.fetchMembers();
                p.fetchStaffStats();
              },
            ),
          ),
        ],
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.blue))
          : trainers.isEmpty
              ? const CustomEmptyStateWidget(
                  icon: Icons.psychology_rounded,
                  title: 'No Trainers Yet',
                  message: 'You haven\'t added any professional staff members yet. Add them from the Members tab.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trainers.length,
                  itemBuilder: (_, i) {
                    final t = trainers[i];
                    final stats = p.staffWorkload.firstWhere(
                      (s) => s.id == t.id,
                      orElse: () => StaffWorkload(id: t.id, name: t.name, role: t.role, tasksAssigned: 0, dietsCreated: 0),
                    );

                    return _TrainerCard(trainer: t, stats: stats);
                  },
                ),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  final MemberModel trainer;
  final StaffWorkload stats;

  const _TrainerCard({required this.trainer, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrainerDetailScreen(trainer: trainer)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.blue.withOpacity(0.1)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cardBackground,
              AppTheme.blue.withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.blue.withOpacity(0.1),
                  child: Text(
                    trainer.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.blue),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trainer.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppTheme.blue, size: 14),
                          const SizedBox(width: 4),
                          Text('Professional Staff', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: AppTheme.border.withOpacity(0.5)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Tasks', stats.tasksAssigned, Icons.assignment_rounded, AppTheme.blue),
                _stat('Diets', stats.dietsCreated, Icons.restaurant_rounded, AppTheme.emerald),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int val, IconData icon, Color color) => Column(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text('$val', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
      const SizedBox(height: 4),
      Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1)),
    ],
  );
}
