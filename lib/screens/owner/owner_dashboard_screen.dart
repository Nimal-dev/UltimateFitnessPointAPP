import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/payment_provider.dart';
import '../../theme/app_theme.dart';
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
                      ),
                      _MetricCard(
                        title: 'PENDING APPROVALS',
                        value: '${p.metrics.pendingRenewals}',
                        icon: Icons.pending_actions_rounded,
                        iconColor: AppTheme.amber,
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
                      ),
                      _MetricCard(
                        title: "TODAY'S CHECK-INS",
                        value: '${p.metrics.dailyCheckins}',
                        icon: Icons.trending_up_rounded,
                        iconColor: AppTheme.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Pending Renewals Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PENDING RENEWALS',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: AppTheme.textMuted)),
                      if (context.watch<PaymentProvider>().pendingPayments.isNotEmpty)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PaymentApprovalsScreen()),
                          ).then((_) => context.read<PaymentProvider>().fetchPendingPayments()),
                          child: Text('VIEW ALL',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accent)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPendingRenewals(context),
                  const SizedBox(height: 12),
                  if (context.watch<PaymentProvider>().paymentHistory.isNotEmpty)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaymentHistoryScreen()),
                        ),
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: Text('VIEW PAYMENT HISTORY',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textMuted),
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Recent Members
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RECENT MEMBERS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: AppTheme.textMuted)),
                    ],
                  ),
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

  Widget _buildPendingRenewals(BuildContext context) {
    final payments = context.watch<PaymentProvider>().pendingPayments;
    final isLoading = context.watch<PaymentProvider>().isLoading;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          : Column(
              children: [
                if (payments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text('No pending renewals',
                          style: GoogleFonts.inter(
                              color: AppTheme.textMuted, fontSize: 13)),
                    ),
                  )
                else
                  ...payments.take(3).map((pay) => _PaymentRequestRow(payment: pay)),
              ],
            ),
    );
  }
}

class _PaymentRequestRow extends StatelessWidget {
  final PaymentRequest payment;
  const _PaymentRequestRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.memberName,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text('UTR: **** ${payment.transactionId}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.amber,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${payment.amount.toInt()}',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Text(payment.planName,
                  style: GoogleFonts.inter(
                      fontSize: 9, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  const _MetricCard({required this.title, required this.value, required this.icon, required this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final dynamic member;
  const _MemberRow({required this.member});

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
    final status = member.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(member.initials,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(member.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(member.email, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _statusColor(status).withOpacity(0.25)),
            ),
            child: Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor(status))),
          ),
        ],
      ),
    );
  }
}
