import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/payment_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/analytics_model.dart';
import '../../models/member_model.dart';
import '../../widgets/premium_tooltip.dart';
import 'payment_approvals_screen.dart';
import 'payment_history_screen.dart';
import 'trainer_detail_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  Future<void> _refreshAllData() async {
    final op = context.read<OwnerProvider>();
    await Future.wait([
      op.fetchMetrics(),
      op.fetchMembers(),
      op.fetchOwnerAnnouncements(),
      op.fetchEngagementLeaderboard(),
      op.fetchStaffStats(),
      op.fetchExpiringMembers(),
      context.read<PaymentProvider>().fetchPendingPayments(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OwnerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.cardBackground,
        onRefresh: _refreshAllData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.cardBackground,
              title: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                  children: const [
                    TextSpan(text: 'GYM ', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'OVERVIEW', style: TextStyle(color: AppTheme.accent)),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
                  ),
                  icon: const Icon(Icons.history_rounded, color: AppTheme.textMuted),
                  tooltip: 'Payment History',
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Good day, Owner 💪', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Here\'s your gym at a glance.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                  const SizedBox(height: 24),

                  // Metric Cards Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.0,
                    children: [
                      _MetricCard(
                        title: 'ACTIVE MEMBERS',
                        value: '${p.metrics.activeMembers}',
                        icon: Icons.person_rounded,
                        iconColor: AppTheme.green,
                        tooltip: 'Members with currently active memberships',
                      ),
                      _MetricCard(
                        title: 'PENDING APPROVALS',
                        value: '${p.metrics.pendingRenewals}',
                        icon: Icons.pending_actions_rounded,
                        iconColor: AppTheme.amber,
                        tooltip: 'New membership or renewal requests waiting for your approval',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaymentApprovalsScreen()),
                        ),
                      ),
                      _MetricCard(
                        title: 'TOTAL MEMBERS',
                        value: '${p.metrics.totalMembers}',
                        icon: Icons.group_rounded,
                        iconColor: AppTheme.accent,
                        tooltip: 'Total number of members ever registered in your gym',
                      ),
                      _MetricCard(
                        title: "TODAY'S CHECK-INS",
                        value: '${p.metrics.dailyCheckins}',
                        icon: Icons.trending_up_rounded,
                        iconColor: AppTheme.blue,
                        tooltip: 'Number of members who have checked in today',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 1. REVENUE FORECASTING SECTION
                  _buildSectionHeader('REVENUE FORECAST (MOM)', tooltip: 'Projected income based on members whose memberships expire in the next 3 months'),
                  const SizedBox(height: 12),
                  _buildRevenueChart(p.metrics.revenueProjections),
                  const SizedBox(height: 28),

                  // 2. ACTIVE ANNOUNCEMENTS (NEW PHASE 2)
                  _buildSectionHeader('GLOBAL ANNOUNCEMENTS 📢', 
                    tooltip: 'Broadcast messages to all gym members. Promos, closures, and events appear here.',
                    action: IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppTheme.accent),
                      onPressed: () => _showCreateAnnouncementDialog(context),
                    )
                  ),
                  const SizedBox(height: 12),
                  _buildAnnouncementsSection(p.announcements),
                  const SizedBox(height: 28),

                  // 3. ENGAGEMENT LEADERBOARD (NEW PHASE 2)
                  _buildSectionHeader('MEMBER LEADERBOARD 🏆', tooltip: 'Top 10 members ranked by engagement points earned through training and tasks.'),
                  const SizedBox(height: 12),
                  _buildLeaderboard(p.engagementLeaderboard),
                  const SizedBox(height: 28),

                  // 4. AT RISK MEMBERS (CHURN) SECTION
                  _buildSectionHeader('CHURN RISK ZONE ⚠️', tooltip: 'Active members who haven\'t checked in for 10 or more days. Reaching out helps retention!'),
                  const SizedBox(height: 12),
                  _buildRiskZone(p.metrics.atRiskMembers),
                  const SizedBox(height: 28),

                  // 5. PEAK HOUR HEATMAP SECTION
                  _buildSectionHeader('PEAK HOUR INSIGHTS 🔥', tooltip: 'Occupancy trends based on check-ins over the last 30 days to help with staffing'),
                  const SizedBox(height: 12),
                  _buildPeakHourHeatmap(p.metrics.peakHours),
                  const SizedBox(height: 28),

                  // 6. OPERATIONS & STAFFING (NEW PHASE 3)
                  _buildSectionHeader('OPERATIONS & STAFFING 🛡️', tooltip: 'Monitor trainer activity and prevent membership churn with renewal reminders.'),
                  const SizedBox(height: 12),
                  _buildStaffWorkload(p.staffWorkload),
                  const SizedBox(height: 16),
                  _buildExpiringWatchlist(p.expiringMembers),
                  const SizedBox(height: 28),

                  // Pending Renewals Section
                  _buildSectionHeader('PENDING RENEWALS', tooltip: 'Quick list of recent membership renewal requests'),
                  const SizedBox(height: 12),
                  _buildPendingRenewals(context),
                  const SizedBox(height: 20),

                  // Recent Members Section (Expanded Phase 4 Tabs)
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSectionHeader('DIRECTORY & STAFF', tooltip: 'All registered users in your gym community.'),
                        const SizedBox(height: 12),
                        TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          dividerColor: Colors.transparent,
                          indicatorColor: AppTheme.accent,
                          labelColor: AppTheme.accent,
                          unselectedLabelColor: AppTheme.textMuted,
                          labelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                          tabs: const [
                            Tab(text: 'ALL'),
                            Tab(text: 'MEMBERS'),
                            Tab(text: 'TRAINERS'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 350, // Fixed height for list area
                          child: TabBarView(
                            children: [
                              _buildUserList(p, 'all'),
                              _buildUserList(p, 'Member'),
                              _buildUserList(p, 'Trainer'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(OwnerProvider p, String roleFilter) {
    var list = p.members;
    if (roleFilter != 'all') {
      list = list.where((m) => m.role == roleFilter).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: p.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : list.isEmpty
              ? Center(child: Text('No entries found', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(color: AppTheme.border.withOpacity(0.5), height: 1, indent: 60),
                  itemBuilder: (context, index) => _MemberRow(
                    member: list[index],
                    staffWorkload: list[index].role == 'Trainer' 
                      ? p.staffWorkload.firstWhere((s) => s.id == list[index].id, orElse: () => StaffWorkload(id: '', name: '', role: '', tasksAssigned: 0, dietsCreated: 0)) 
                      : null,
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title, {String? tooltip, Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppTheme.textMuted)),
            if (tooltip != null) ...[
              const SizedBox(width: 6),
              PremiumTooltip(
                message: tooltip,
               child: const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted),
              ),
            ],
          ],
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildAnnouncementsSection(List<AnnouncementModel> announcements) {
    if (announcements.isEmpty) return _emptyPlaceholder('No active announcements. Create one to notify members!');
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final a = announcements[index];
          return PremiumTooltip(
            message: 'Target: ${a.target}\nStatus: ${a.isActive ? 'Live' : 'Hidden'}',
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: a.isActive ? AppTheme.accent.withOpacity(0.2) : AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(a.type.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.read<OwnerProvider>().deleteAnnouncement(a.id),
                        child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppTheme.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(a.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboard(List<LeaderboardEntry> leaderboard) {
    if (leaderboard.isEmpty) return _emptyPlaceholder('Members need to earn points to appear here!');
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: List.generate(leaderboard.length, (i) {
          final entry = leaderboard[i];
          final isTop3 = i < 3;
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: Container(
                  width: 24,
                  alignment: Alignment.center,
                  child: isTop3 
                    ? Icon([Icons.workspace_premium_rounded, Icons.emoji_events_rounded, Icons.military_tech_rounded][i], 
                        size: 18, color: [const Color(0xFFFFD700), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)][i])
                    : Text('${i + 1}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                ),
                title: Text(entry.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                trailing: PremiumTooltip(
                  message: 'Total points earned from activities',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${entry.points}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.accent)),
                      const SizedBox(width: 4),
                      const Icon(Icons.bolt_rounded, size: 14, color: AppTheme.accent),
                    ],
                  ),
                ),
              ),
              if (i < leaderboard.length - 1) Divider(color: AppTheme.border.withOpacity(0.5), height: 1, indent: 50),
            ],
          );
        }),
      ),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedType = 'Info';
    String selectedTarget = 'All';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.border)),
          title: Text('New Announcement 📢', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: const TextStyle(color: AppTheme.textMuted),
                    hintText: 'e.g. Holiday Closure',
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.border)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    labelStyle: const TextStyle(color: AppTheme.textMuted),
                    hintText: 'Describe your update...',
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.border)),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  dropdownColor: AppTheme.cardBackground,
                  value: selectedType,
                  items: ['Info', 'Alert', 'Promo', 'Event'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                  decoration: const InputDecoration(labelText: 'Type', labelStyle: TextStyle(color: AppTheme.textMuted)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  context.read<OwnerProvider>().createAnnouncement({
                    'title': titleController.text,
                    'content': contentController.text,
                    'type': selectedType,
                    'target': selectedTarget,
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              child: const Text('BROADCAST', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List<RevenueProjection> projections) {
    if (projections.isEmpty) return _emptyPlaceholder('No projections available');
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Projected 3-Month Income', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: projections.map((p) {
                final h = (p.projectedRevenue / 10000 * 100).clamp(10.0, 100.0);
                return PremiumTooltip(
                  message: 'Projected Revenue: ₹${p.projectedRevenue.toStringAsFixed(0)}\nRenewals: ${p.count}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.accent, Color(0xFFD4E600)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${_getMonthName(p.month)}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskZone(List<AtRiskMember> members) {
    if (members.isEmpty) return _emptyPlaceholder('No members at risk right now!');
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        itemBuilder: (context, index) {
          final m = members[index];
          return PremiumTooltip(
            message: 'Last seen: ${m.lastCheckin != null ? m.lastCheckin!.toString().split(' ')[0] : 'Never'}',
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Inactive >10d', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.red)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {}, // WhatsApp integration placeholder
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppTheme.green),
                          const SizedBox(width: 4),
                          Text('REACH OUT', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.green)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeakHourHeatmap(List<PeakHour> hours) {
    if (hours.isEmpty) return _emptyPlaceholder('Not enough check-in data yet');
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(24, (i) {
          final hourData = hours.firstWhere((h) => h.hour == i, orElse: () => PeakHour(hour: i, count: 0));
          final h = (hourData.count * 10.0).clamp(4.0, 80.0);
          final isPeak = hourData.count > 0;
          return PremiumTooltip(
            message: 'Hour: $i:00 - ${i+1}:00\nCheck-ins: ${hourData.count}',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: i % 2 == 0 ? 6 : 4,
                  height: h,
                  decoration: BoxDecoration(
                    color: i >= 17 && i <= 20 ? AppTheme.amber : (isPeak ? AppTheme.blue : Colors.white.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                if (i % 6 == 0) Text('${i}h', style: GoogleFonts.inter(fontSize: 8, color: AppTheme.textMuted)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _emptyPlaceholder(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
      child: Center(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted))),
    );
  }

  String _getMonthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  Widget _buildPendingRenewals(BuildContext context) {
    final payments = context.watch<PaymentProvider>().pendingPayments;
    final isLoading = context.watch<PaymentProvider>().isLoading;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    if (payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(child: Text('No pending renewals', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: payments.take(3).map((p) => _PaymentRequestRow(payment: p)).toList(),
      ),
    );
  }

  Widget _buildStaffWorkload(List<StaffWorkload> data) {
    if (data.isEmpty) return _emptyPlaceholder('No staff data available');
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final s = data[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(s.role, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _activityBadge(Icons.assignment_rounded, s.tasksAssigned, 'Tasks', AppTheme.blue),
                    _activityBadge(Icons.restaurant_rounded, s.dietsCreated, 'Diets', AppTheme.green),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _activityBadge(IconData icon, int count, String label, Color color) {
    return PremiumTooltip(
      message: '$count $label assigned/created',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text('$count', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringWatchlist(List<ExpiringMember> members) {
    if (members.isEmpty) return _emptyPlaceholder('No memberships expiring in the next 7 days.');
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: members.map((m) => ListTile(
          dense: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.timer_rounded, color: AppTheme.red, size: 18),
          ),
          title: Text(m.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text('Expires in ${m.daysRemaining} days', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.red)),
          trailing: PremiumTooltip(
            message: 'Send a renewal reminder to ${m.name}',
            child: ElevatedButton(
              onPressed: () async {
                final success = await context.read<OwnerProvider>().sendRenewalReminder(m.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reminder sent to ${m.name}! 📲'), backgroundColor: AppTheme.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                minimumSize: const Size(60, 28),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('REMIND', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _PaymentRequestRow extends StatelessWidget {
  final PaymentRequest payment;
  const _PaymentRequestRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaymentApprovalsScreen()),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.payment_rounded, color: AppTheme.amber, size: 20),
      ),
      title: Text(payment.memberName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Text('₹${payment.amount}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? tooltip;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 2),
              Text(title, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );

    if (tooltip != null) {
      card = PremiumTooltip(
        message: tooltip!,
        child: card,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}

class _MemberRow extends StatelessWidget {
  final MemberModel member;
  final StaffWorkload? staffWorkload;
  const _MemberRow({required this.member, this.staffWorkload});

  Color _statusColor(String s) {
    if (s == 'Active') return AppTheme.green;
    if (s == 'Pending') return AppTheme.amber;
    if (s == 'Expired') return AppTheme.red;
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final isTrainer = member.role == 'Trainer';

    return ListTile(
      onTap: isTrainer 
        ? () => _openTrainerDetails(context) 
        : null, // Members already have their own analytics screen handled elsewhere or by owner clicks in members tab
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: (isTrainer ? AppTheme.blue : AppTheme.accent).withOpacity(0.1),
        child: Text(member.name.substring(0, 1).toUpperCase(), 
          style: TextStyle(color: isTrainer ? AppTheme.blue : AppTheme.accent, fontWeight: FontWeight.bold)),
      ),
      title: Text(member.name, 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Text(isTrainer ? 'Professional Trainer' : member.mobile, 
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
      trailing: isTrainer && staffWorkload != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniBadge(Icons.assignment_rounded, staffWorkload!.tasksAssigned, AppTheme.blue),
              const SizedBox(width: 6),
              _miniBadge(Icons.restaurant_rounded, staffWorkload!.dietsCreated, AppTheme.green),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 16),
            ],
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(member.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(member.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: _statusColor(member.status))),
          ),
    );
  }

  Widget _miniBadge(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Icon(icon, size: 8, color: color),
          const SizedBox(width: 2),
          Text('$count', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _openTrainerDetails(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TrainerDetailScreen(trainer: member)));
  }
}
