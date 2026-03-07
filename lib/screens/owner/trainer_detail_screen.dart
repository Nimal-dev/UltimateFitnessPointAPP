import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/member_model.dart';
import '../../widgets/premium_tooltip.dart';
import '../shared/member_analytics_screen.dart';

class TrainerDetailScreen extends StatefulWidget {
  final MemberModel trainer;
  const TrainerDetailScreen({super.key, required this.trainer});

  @override
  State<TrainerDetailScreen> createState() => _TrainerDetailScreenState();
}

class _TrainerDetailScreenState extends State<TrainerDetailScreen> {
  Map<String, dynamic>? performance;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformance();
  }

  Future<void> _loadPerformance() async {
    final data = await context.read<OwnerProvider>().fetchTrainerPerformance(widget.trainer.id);
    if (mounted) {
      setState(() {
        performance = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(widget.trainer.name, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: _loadPerformance,
              color: AppTheme.accent,
              backgroundColor: AppTheme.cardBackground,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: AppTheme.blue.withOpacity(0.1),
                            child: Text(widget.trainer.name.substring(0, 1).toUpperCase(), 
                              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.blue)),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.trainer.name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                                Text('Professional Trainer', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text('ACTIVE STATUS', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.green)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Stats Grid
                    _buildSectionHeader('ASSIGNMENT SUMMARY', tooltip: 'Aggregate of all tasks and diet plans this trainer has assigned across the gym.'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'TASKS ASSIGNED',
                            value: '${performance?['stats']['tasksCount'] ?? 0}',
                            icon: Icons.assignment_rounded,
                            color: AppTheme.blue,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _StatBox(
                            label: 'DIETS CREATED',
                            value: '${performance?['stats']['dietsCount'] ?? 0}',
                            icon: Icons.restaurant_rounded,
                            color: AppTheme.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Managed Members
                    _buildSectionHeader('MANAGED MEMBERS', 
                      tooltip: 'Members currently receiving training support, diet plans, or habit tracking from this trainer.'),
                    const SizedBox(height: 12),
                    _buildManagedMembersList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, {String? tooltip}) {
    return Row(
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppTheme.textMuted)),
        if (tooltip != null) ...[
          const SizedBox(width: 6),
          PremiumTooltip(
            message: tooltip,
            child: const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildManagedMembersList() {
    final members = (performance?['managedMembers'] as List? ?? []);
    
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: Text('Not managing any members yet', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: members.map((m) {
          final isLast = members.indexOf(m) == members.length - 1;
          return Column(
            children: [
              ListTile(
                onTap: () {
                  final memberModel = MemberModel(
                    id: m['_id'],
                    name: m['name'],
                    email: m['email'] ?? '',
                    mobile: m['mobile'] ?? '',
                    status: m['membershipStatus'] ?? 'Active',
                    role: 'Member',
                    points: m['points'] ?? 0,
                    joined: '', // Optional for analytics
                    expiryDate: m['membershipExpiry'] ?? '',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberAnalyticsScreen(member: memberModel),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.accent.withOpacity(0.1),
                  child: Text(m['name'].substring(0, 1).toUpperCase(), 
                    style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                ),
                title: Text(m['name'], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(m['membershipStatus'], 
                  style: GoogleFonts.inter(fontSize: 11, color: m['membershipStatus'] == 'Active' ? AppTheme.green : AppTheme.textMuted)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
              ),
              if (!isLast) Divider(color: AppTheme.border.withOpacity(0.5), height: 1, indent: 60),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
