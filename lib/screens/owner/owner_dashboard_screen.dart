import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/payment_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/analytics_model.dart';
import '../../models/member_model.dart';
import 'payment_approvals_screen.dart';
import 'payment_history_screen.dart';

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
      context.read<OwnerProvider>().fetchMetrics();
      context.read<OwnerProvider>().fetchMembers();
      context.read<PaymentProvider>().fetchPendingPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OwnerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.cardBackground,
        onRefresh: () async {
          await p.fetchMetrics();
          await p.fetchMembers();
          if (mounted) await context.read<PaymentProvider>().fetchPendingPayments();
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

                  // 2. AT RISK MEMBERS (CHURN) SECTION
                  _buildSectionHeader('CHURN RISK ZONE ⚠️', tooltip: 'Active members who haven\'t checked in for 10 or more days. Reaching out helps retention!'),
                  const SizedBox(height: 12),
                  _buildRiskZone(p.metrics.atRiskMembers),
                  const SizedBox(height: 28),

                  // 3. PEAK HOUR HEATMAP SECTION
                  _buildSectionHeader('PEAK HOUR INSIGHTS 🔥', tooltip: 'Occupancy trends based on check-ins over the last 30 days to help with staffing'),
                  const SizedBox(height: 12),
                  _buildPeakHourHeatmap(p.metrics.peakHours),
                  const SizedBox(height: 28),

                  // Pending Renewals Section
                  _buildSectionHeader('PENDING RENEWALS', tooltip: 'Quick list of recent membership renewal requests'),
                  const SizedBox(height: 12),
                  _buildPendingRenewals(context),
                  const SizedBox(height: 20),

                  // Recent Members Section
                  _buildSectionHeader('RECENT MEMBERS', tooltip: 'The most recently registered members in your gym'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: p.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                          )
                        : Column(
                            children: [
                              ...p.members.take(5).map((m) => _MemberRow(member: m)).toList(),
                              if (p.members.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Text('No members yet', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
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

  Widget _buildSectionHeader(String title, {String? tooltip}) {
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
      ],
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
}

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
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
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

class _PaymentRequestRow extends StatelessWidget {
  final dynamic payment;
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
      title: Text(payment['userName'] ?? 'Member', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Text('₹${payment['amount']}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
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
  const _MemberRow({required this.member});

  Color _statusColor(String s) {
    if (s == 'Active') return AppTheme.green;
    if (s == 'Pending') return AppTheme.amber;
    if (s == 'Expired') return AppTheme.red;
    return AppTheme.textMuted;
  }

  String _statusTooltip(String s) {
    if (s == 'Active') return 'Member has an active membership';
    if (s == 'Pending') return 'Member registration or renewal is pending approval';
    if (s == 'Expired') return 'Membership has expired and needs renewal';
    return 'Status: $s';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.accent.withOpacity(0.1),
        child: Text(member.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
      ),
      title: Text(member.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Text(member.mobile, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
      trailing: PremiumTooltip(
        message: _statusTooltip(member.status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(member.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(member.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: _statusColor(member.status))),
        ),
      ),
    );
  }
}
