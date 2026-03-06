import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import '../../theme/app_theme.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchMetrics();
      context.read<OwnerProvider>().fetchMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OwnerProvider>();
    final activeMembers = p.members.where((m) => m.status == 'Active').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.cardBackground,
        onRefresh: () async {
          await p.fetchMetrics();
          await p.fetchMembers();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.cardBackground,
              title: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                  children: const [
                    TextSpan(text: 'TRAINER ', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'DASHBOARD', style: TextStyle(color: AppTheme.accent)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Ready to train today? 🏋️', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Here\'s an overview of your clients.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(children: [
                    Expanded(child: _StatCard(label: 'ACTIVE CLIENTS', value: '${p.metrics.activeMembers}', icon: Icons.people_rounded, color: AppTheme.accent)),
                    const SizedBox(width: 14),
                    Expanded(child: _StatCard(label: "TODAY'S CHECK-INS", value: '${p.metrics.dailyCheckins}', icon: Icons.how_to_reg_rounded, color: AppTheme.blue)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _StatCard(label: 'PENDING APPROVAL', value: '${p.metrics.pendingRenewals}', icon: Icons.pending_rounded, color: AppTheme.amber)),
                    const SizedBox(width: 14),
                    Expanded(child: _StatCard(label: 'TOTAL MEMBERS', value: '${p.metrics.totalMembers}', icon: Icons.group_rounded, color: AppTheme.emerald)),
                  ]),
                  const SizedBox(height: 28),

                  Text('ACTIVE CLIENTS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: AppTheme.textMuted)),
                  const SizedBox(height: 12),

                  if (p.isLoading)
                    const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  else if (activeMembers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Center(child: Text('No active clients yet', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13))),
                    )
                  else
                    ...activeMembers.take(6).map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(m.initials, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.accent)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text(m.email, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.green.withOpacity(0.2))),
                            child: Text('${m.points} pts', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.green)),
                          ),
                        ]),
                      ),
                    )),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ]),
    );
  }
}
