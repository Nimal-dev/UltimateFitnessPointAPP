import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/member_model.dart';
import '../shared/diet_plan_editor_screen.dart';
import '../shared/member_analytics_screen.dart';

class TrainerClientsScreen extends StatefulWidget {
  const TrainerClientsScreen({super.key});

  @override
  State<TrainerClientsScreen> createState() => _TrainerClientsScreenState();
}

class _TrainerClientsScreenState extends State<TrainerClientsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchMembers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDietEditor(MemberModel member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DietPlanEditorScreen(
          memberId: member.id,
          memberName: member.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OwnerProvider>();
    final activeMembers = p.members.where((m) {
      if (m.status != 'Active') return false;
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return m.name.toLowerCase().contains(q) || m.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.cardBackground,
            title: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                children: const [
                  TextSpan(text: 'CLIENT ', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'DIETS', style: TextStyle(color: AppTheme.accent)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search clients...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                          onPressed: () { setState(() => _search = ''); _searchCtrl.clear(); },
                        )
                      : null,
                ),
              ),
            ),
          ),
          if (p.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (activeMembers.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.people_outline_rounded, color: AppTheme.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text('No active clients', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Active members will appear here', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ClientCard(
                      member: activeMembers[i],
                      onAssignDiet: () => _openDietEditor(activeMembers[i]),
                      onViewStats: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemberAnalyticsScreen(
                            member: activeMembers[i],
                          ),
                        ),
                      ),
                    ),
                  ),
                  childCount: activeMembers.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final MemberModel member;
  final VoidCallback onAssignDiet;
  final VoidCallback onViewStats;
  const _ClientCard({required this.member, required this.onAssignDiet, required this.onViewStats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.1)),
          ),
          child: Center(child: Text(member.initials, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.accent))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(member.email, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text('${member.points} pts', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w700)),
        ])),
        IconButton(
          onPressed: onViewStats,
          icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.emerald, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onAssignDiet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.restaurant_menu_rounded, color: AppTheme.accent, size: 14),
              const SizedBox(width: 4),
              Text('Diet Plan', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accent)),
            ]),
          ),
        ),
      ]),
    );
  }
}
