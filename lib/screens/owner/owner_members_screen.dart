import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/member_model.dart';
import '../../utils/dialog_utils.dart';
import '../../widgets/custom_empty_state_widget.dart';
import '../shared/diet_plan_editor_screen.dart';
import '../shared/member_analytics_screen.dart';

class OwnerMembersScreen extends StatefulWidget {
  const OwnerMembersScreen({super.key});

  @override
  State<OwnerMembersScreen> createState() => _OwnerMembersScreenState();
}

class _OwnerMembersScreenState extends State<OwnerMembersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchMembers();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _currentTab {
    switch (_tabCtrl.index) {
      case 1: return 'pending';
      case 2: return 'expired';
      case 3: return 'rejected';
      default: return 'active';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OwnerProvider>();
    final filtered = p.filtered(_currentTab, _search);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.cardBackground,
            title: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                children: const [
                  TextSpan(text: 'MEMBER ', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'MANAGEMENT', style: TextStyle(color: AppTheme.accent)),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_rounded, color: AppTheme.accent),
                onPressed: () => _showAddMemberSheet(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              onTap: (_) => setState(() {}),
              indicatorColor: AppTheme.accent,
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              tabs: [
                const Tab(text: 'ACTIVE'),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('PENDING'),
                    if (p.pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppTheme.red, borderRadius: BorderRadius.circular(6)),
                        child: Text('${p.pendingCount}', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ],
                  ]),
                ),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('EXPIRED'),
                    if (p.expiredCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppTheme.amber, borderRadius: BorderRadius.circular(6)),
                        child: Text('${p.expiredCount}', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ],
                  ]),
                ),
                const Tab(text: 'REJECTED'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search by name, email or mobile...',
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
            // Member list
            Expanded(
              child: p.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                      : filtered.isEmpty
                          ? CustomEmptyStateWidget(
                              icon: Icons.person_search_rounded,
                              title: 'No Members Here',
                              message: 'No members match your search. Add a new member or try a different filter.',
                            )
                          : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _MemberTile(
                            member: filtered[i],
                            tab: _currentTab,
                            onApprove: () => p.updateMemberStatus(filtered[i].id, 'Active'),
                            onReject: () => p.updateMemberStatus(filtered[i].id, 'Rejected'),
                            onUndoReject: () => p.updateMemberStatus(filtered[i].id, 'Pending'),
                            onDelete: () => _confirmDelete(context, p, filtered[i]),
                            onAssignDiet: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DietPlanEditorScreen(
                                  memberId: filtered[i].id,
                                  memberName: filtered[i].name,
                                ),
                              ),
                            ),
                            onViewStats: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MemberAnalyticsScreen(
                                  member: filtered[i],
                                ),
                              ),
                            ),
                            onToggleStatus: () {
                              const statuses = ['Active', 'Pending', 'Expired', 'Rejected'];
                              final next = statuses[(statuses.indexOf(filtered[i].status) + 1) % statuses.length];
                              p.updateMemberStatus(filtered[i].id, next);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, OwnerProvider p, MemberModel m) async {
    final confirmed = await DialogUtils.showConfirmation(
      context: ctx,
      title: '⚠️ Remove ${m.name}?',
      message: 'This will permanently delete ${m.name}\'s account and all their data. This cannot be undone — are you sure you want to bench them for good?',
      confirmText: 'Delete',
      cancelText: 'Keep',
      isDestructive: true,
    );
    if (confirmed == true) {
      p.deleteMember(m.id);
    }
  }

  void _showAddMemberSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    String role = 'Member';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Add New Member', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 20),
              _sheetField(nameCtrl, 'Full Name', Icons.person_outline_rounded),
              const SizedBox(height: 14),
              _sheetField(emailCtrl, 'Email', Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _sheetField(mobileCtrl, 'Mobile', Icons.phone_outlined, keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderMid),
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: role,
                    dropdownColor: AppTheme.cardBackground,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    isExpanded: true,
                    items: ['Member', 'Trainer'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setS(() => role = v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final p = context.read<OwnerProvider>();
                    final ok = await p.addMember({
                      'name': nameCtrl.text,
                      'email': emailCtrl.text,
                      'mobile': mobileCtrl.text,
                      'role': role,
                    });
                    if (ok && ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text('ADD MEMBER', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType keyboard = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        ),
      );
}

class _MemberTile extends StatelessWidget {
  final MemberModel member;
  final String tab;
  final VoidCallback onApprove, onReject, onUndoReject, onDelete, onToggleStatus, onAssignDiet, onViewStats;

  const _MemberTile({
    required this.member,
    required this.tab,
    required this.onApprove,
    required this.onReject,
    required this.onUndoReject,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onAssignDiet,
    required this.onViewStats,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'Active': return AppTheme.green;
      case 'Pending': return AppTheme.amber;
      case 'Expired': return AppTheme.textMuted;
      default: return AppTheme.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewStats,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
                ),
                child: Center(
                  child: Text(member.initials, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.accent)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(member.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(member.email, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                ]),
              ),
              GestureDetector(
                onTap: tab == 'all' ? onToggleStatus : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(member.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor(member.status).withOpacity(0.25)),
                  ),
                  child: Text(member.status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor(member.status))),
                ),
              ),
            ],
          ),
          // Info row
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                _info('Points', '${member.points}'),
                const SizedBox(width: 12),
                _info('Joined', member.joined),
                const Spacer(),
                // Action buttons
                if (tab == 'pending') ...[
                  _actionBtn('Approve', AppTheme.green, onApprove),
                  const SizedBox(width: 6),
                  _actionBtn('Reject', AppTheme.amber, onReject),
                ] else if (tab == 'rejected') ...[
                  _actionBtn('Undo', AppTheme.textMuted, onUndoReject),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: onAssignDiet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.restaurant_menu_rounded, color: AppTheme.accent, size: 13),
                        const SizedBox(width: 3),
                        Text('Diet', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accent)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onViewStats,
                    icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.emerald, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _info(String label, String val) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted, letterSpacing: 0.5)),
    Text(val, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
  ]);

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ),
      );
}
