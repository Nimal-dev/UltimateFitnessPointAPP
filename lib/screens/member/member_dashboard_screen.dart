import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/diet_provider.dart';
import '../../models/user_model.dart';
import '../../models/member_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_tooltip.dart';
import '../shared/member_analytics_screen.dart';
import 'membership_renewal_screen.dart';
import 'profile_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/fitness_log_model.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberProvider>().fetchDashboard(year: _selectedYear);
      context.read<MemberProvider>().fetchMemberAnnouncements();
      context.read<DietProvider>().fetchDietData();
      context.read<MemberProvider>().fetchWeightLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();
    final user = context.watch<AuthProvider>().user;
    final displayUser = provider.userData ?? user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              color: AppTheme.accent,
              backgroundColor: AppTheme.cardBackground,
              onRefresh: () async {
                await Future.wait([
                  context.read<MemberProvider>().fetchDashboard(year: _selectedYear),
                  context.read<MemberProvider>().fetchMemberAnnouncements(),
                  context.read<DietProvider>().fetchDietData(),
                  context.read<MemberProvider>().fetchWeightLogs(),
                ]);
                // Sync profile data to AuthProvider
                final freshUser = context.read<MemberProvider>().userData;
                if (freshUser != null && mounted) {
                  context.read<AuthProvider>().updateLocalUser(freshUser);
                }
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: AppTheme.cardBackground,
                    title: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                        children: [
                          const TextSpan(
                              text: 'MY ',
                              style: TextStyle(color: Colors.white)),
                          const TextSpan(
                              text: 'STATUS',
                              style: TextStyle(color: AppTheme.accent)),
                        ],
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          ),
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.accent, Color(0xFFD4E600)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                user?.initials ?? '?',
                                style: GoogleFonts.inter(
                                  color: AppTheme.charcoal,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Greeting
                        Text(
                          'Hey, ${user?.name.split(' ').first ?? 'Champ'} 👋',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Consistency is the bridge between goals and accomplishment.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Phase 2: Announcements Carousel
                        if (provider.announcements.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "LATEST UPDATES 📢",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: provider.announcements.length,
                              itemBuilder: (context, index) {
                                final a = provider.announcements[index];
                                return Container(
                                  width: 240,
                                  margin: const EdgeInsets.only(right: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBackground,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (a.type == 'Alert' ? AppTheme.red : AppTheme.accent).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              a.type.toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: a.type == 'Alert' ? AppTheme.red : AppTheme.accent,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          PremiumTooltip(
                                            message: 'Posted on ${_todayLabel()}',
                                            child: Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted.withOpacity(0.5)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        a.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        a.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Status + Points Row
                        Row(
                          children: [
                            Expanded(
                              child: _MembershipRingCard(
                                daysRemaining: provider.userData?.daysRemaining ?? 0,
                                status: provider.userData?.membershipStatus ?? 'Pending',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _PointsCard(
                                points: provider.userData?.points ?? 0,
                                tier: provider.userData?.tier ?? 'Bronze',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // BMI Analytics Section
                        if (displayUser?.weight != null && displayUser?.height != null) ...[
                          _BmiCard(user: displayUser!, onInfoTap: _showHealthInfoModal),
                          const SizedBox(height: 16),
                          _MetabolicCard(user: displayUser, onInfoTap: _showHealthInfoModal),
                          const SizedBox(height: 16),
                          
                          // Performance Analytics Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accent,
                                  AppTheme.accent.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _goToAnalytics(displayUser!),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.analytics_rounded, color: Colors.black, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        "VIEW FULL PERFORMANCE",
                                        style: GoogleFonts.inter(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Weight Progress Section
                          _WeightProgressSection(
                            weights: provider.weightLogs,
                            onUpdate: (val) {
                              provider.addWeightLog(
                                val,
                                onSuccess: () {
                                  if (provider.userData != null) {
                                    context.read<AuthProvider>().updateLocalUser(provider.userData!);
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Today's Routine
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "TODAY'S ROUTINE",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.accent.withOpacity(0.2)),
                              ),
                              child: Text(
                                _todayLabel(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (provider.tasks.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Center(
                              child: Text(
                                'No tasks assigned yet',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          ...provider.tasks.map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TaskItem(
                                task: task,
                                onTap: () => provider.toggleTask(task.id),
                              ),
                            ),
                          ),

                        const SizedBox(height: 28),
                        // Activity Heatmap Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ACTIVITY HEATMAP',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            // Year selector
                            Row(
                              children: [2026, 2025, 2024].map((y) {
                                final selected = y == _selectedYear;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedYear = y);
                                    provider.fetchDashboard(year: y);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppTheme.accent
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$y',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: selected
                                            ? AppTheme.charcoal
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ActivityHeatmap(
                          activity: provider.activity,
                          year: _selectedYear,
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

  void _showHealthInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.borderMid, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HEALTH ANALYTICS GUIDE', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Understand your metrics and how to use them for your goals.', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                    const Divider(height: 48, color: AppTheme.border),
                    
                    _infoSection('BMI (Body Mass Index)', 'A simple calculation using weight and height to determine weight category.', [
                      'Underweight: < 18.5',
                      'Healthy Weight: 18.5 - 24.9',
                      'Overweight: 25 - 29.9',
                      'Obese: > 30'
                    ]),
                    
                    const SizedBox(height: 32),
                    _infoSection('BMR (Basal Metabolic Rate)', 'The calories your body burns at exact rest just to keep you alive (organs, breathing, etc).', [
                      'Calculated via Mifflin-St Jeor Equation.',
                      'It is your metabolic "idle" speed.',
                      'NEVER eat below your BMR without guidance.'
                    ]),

                    const SizedBox(height: 32),
                    _infoSection('TDEE (Total Daily Burn)', 'The total calories you burn in a day including all your movement and physical activity.', [
                      'TDEE = BMR × Activity Multiplier.',
                      'To Lose Weight: Eat ~500 kcal below TDEE.',
                      'To Maintain: Eat EXACTLY your TDEE.',
                      'To Build Muscle: Eat 250-500 kcal above TDEE.'
                    ]),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('GOT IT, CHAMP!'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String title, String desc, List<String> bullets) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.accent)),
      const SizedBox(height: 8),
      Text(desc, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, height: 1.5)),
      const SizedBox(height: 12),
      ...bullets.map((b) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.accent),
            const SizedBox(width: 8),
            Expanded(child: Text(b, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary))),
          ],
        ),
      )),
    ],
  );

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  void _goToAnalytics(UserModel user) {
    final member = MemberModel(
      id: user.id,
      name: user.name,
      email: user.email,
      mobile: user.mobile ?? '',
      status: user.membershipStatus,
      points: user.points,
      joined: '', // Not strictly needed for member self-view
      expiryDate: user.membershipExpiry?.toIso8601String() ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberAnalyticsScreen(member: member),
      ),
    );
  }
}

class _MembershipRingCard extends StatefulWidget {
  final int daysRemaining;
  final String status;
  const _MembershipRingCard(
      {required this.daysRemaining, required this.status});

  @override
  State<_MembershipRingCard> createState() => _MembershipRingCardState();
}

class _MembershipRingCardState extends State<_MembershipRingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.daysRemaining / 30).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => CustomPaint(
                painter: _RingPainter(
                  progress: pct * _anim.value,
                  color: AppTheme.accent,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.daysRemaining}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'DAYS\nLEFT',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ACTIVE PLAN',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.status == 'Active' ? 'Premium' : widget.status,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MembershipRenewalScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent.withOpacity(0.1),
                foregroundColor: AppTheme.accent,
                side: BorderSide(color: AppTheme.accent.withOpacity(0.3)),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'RENEW NOW',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    paint.color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _PointsCard extends StatelessWidget {
  final int points;
  final String tier;
  const _PointsCard({required this.points, required this.tier});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'POINTS',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              Icon(Icons.emoji_events_rounded,
                  color: AppTheme.accent.withOpacity(0.3), size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            points.toString(),
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            'PTS',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppTheme.accent.withOpacity(0.2)),
            ),
            child: Text(
              '$tier Tier',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;
  const _TaskItem({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool completed = task.isCompleted;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: completed
              ? AppTheme.accent.withOpacity(0.05)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed
                ? AppTheme.accent.withOpacity(0.2)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: completed ? AppTheme.accent : AppTheme.textMuted,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: completed
                          ? Colors.white.withOpacity(0.4)
                          : Colors.white,
                      decoration: completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: AppTheme.accent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '+${task.points} Points',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!completed)
              Text(
                'COMPLETE',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onInfoTap;
  const _BmiCard({required this.user, required this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    final bmi = user.bmi ?? 0;
    final category = user.bmiCategory;
    final color = user.bmiColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('BODY MASS INDEX', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.5)),
                      const SizedBox(width: 4),
                   const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onInfoTap,
                        child: const Icon(Icons.info_outline_rounded, size: 12, color: AppTheme.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(category.toUpperCase(), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
                child: Text(bmi.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // BMI Gauge
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Color(0xFFD4E600), Colors.orange, Colors.red],
                  ),
                ),
              ),
              // Indicator
              AnimatedAlign(
                duration: const Duration(seconds: 1),
                alignment: Alignment((((bmi.clamp(15, 35) - 15) / 20) * 2) - 1, 0),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.background, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bmiLabel('15', 'Under'),
              _bmiLabel('22', 'Healthy'),
              _bmiLabel('27', 'Over'),
              _bmiLabel('35+', 'Obese'),
            ],
          ),
          const Divider(height: 48, color: AppTheme.border),
          
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IDEAL WEIGHT RANGE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text('Based on your height, you should be ${user.idealWeightRange}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bmiLabel(String val, String cat) => Column(
    children: [
      Text(val, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(cat, style: GoogleFonts.inter(fontSize: 8, color: AppTheme.textMuted)),
    ],
  );
}

class _MetabolicCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onInfoTap;
  const _MetabolicCard({required this.user, required this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    final bmr = user.bmr;
    final tdee = user.tdee;
    final hasMetabolicData = bmr != null && tdee != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('METABOLIC PROFILE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.accent, letterSpacing: 1.5)),
                  if (hasMetabolicData) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onInfoTap,
                      child: const Icon(Icons.help_outline_rounded, size: 12, color: AppTheme.accent),
                    ),
                  ],
                ],
              ),
              if (!hasMetabolicData)
                Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.accent.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 20),
          if (hasMetabolicData) ...[
            Row(
              children: [
                Expanded(
                  child: _MetabolicStat(
                    label: 'BMR',
                    sub: 'Resting Calories',
                    value: bmr.toStringAsFixed(0),
                    icon: Icons.nightlight_round,
                    color: Colors.blueAccent,
                  ),
                ),
                Container(width: 1, height: 40, color: AppTheme.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
                Expanded(
                  child: _MetabolicStat(
                    label: 'TDEE',
                    sub: 'Daily Burn',
                    value: tdee.toStringAsFixed(0),
                    icon: Icons.local_fire_department_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const Divider(height: 40, color: AppTheme.border),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To lose weight, aim for ${ (tdee - 500).toStringAsFixed(0) } kcal per day.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ] else
            Column(
              children: [
                Text(
                  'Complete your profile with Age and Gender to unlock your BMR & TDEE analytics.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accent),
                      foregroundColor: AppTheme.accent,
                    ),
                    child: const Text('SETUP METRICS'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetabolicStat extends StatelessWidget {
  final String label, sub, value;
  final IconData icon;
  final Color color;
  const _MetabolicStat({required this.label, required this.sub, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final String tooltipMsg = label == 'BMR' 
      ? 'Calories your body burns at rest just to survive.' 
      : 'Total calories burned including your daily activity.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(width: 4),
            Tooltip(
              message: tooltipMsg,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 5),
              preferBelow: false,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
              ),
              textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Icon(Icons.info_outline_rounded, size: 10, color: AppTheme.textMuted.withOpacity(0.5)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(sub, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted)),
      ],
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  final Map<String, int> activity;
  final int year;
  const _ActivityHeatmap({required this.activity, required this.year});

  Color _cellColor(int count) {
    if (count == 0) return const Color(0xFF161B22);
    if (count == 1) return AppTheme.accent.withOpacity(0.3);
    if (count == 2) return AppTheme.accent.withOpacity(0.6);
    return AppTheme.accent;
  }

  String _getMonthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Build 52-week grid
    DateTime start = DateTime(year, 1, 1);
    // Start on Sunday
    start = start.subtract(Duration(days: start.weekday % 7));
    const weeks = 53;
    final cells = <Widget>[];

    // Calculate month labels positions
    final monthLabels = <int, String>{};
    for (int i = 0; i < weeks * 7; i++) {
      final date = start.add(Duration(days: i));
      if (date.day == 1 && date.year == year) {
        monthLabels[i ~/ 7] = _getMonthName(date.month);
      }
    }

    for (int w = 0; w < weeks; w++) {
      final col = <Widget>[];
      for (int d = 0; d < 7; d++) {
        final date = start.add(Duration(days: w * 7 + d));
        if (date.year != year) {
          col.add(const SizedBox(width: 10, height: 10));
        } else {
          final key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final count = activity[key] ?? 0;
          col.add(Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _cellColor(count),
              borderRadius: BorderRadius.circular(2),
            ),
          ));
        }
        if (d < 6) col.add(const SizedBox(height: 3));
      }
      cells.add(Column(children: col));
      if (w < weeks - 1) cells.add(const SizedBox(width: 3));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderMid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120, // Increased height for more breathing room
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Labels (Static on the left)
                Padding(
                  padding: const EdgeInsets.only(top: 22), // Align with grid rows (below months)
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 13), // Sunday
                      _dayLabel('Mon'),
                      const SizedBox(height: 13), // Tuesday
                      _dayLabel('Wed'),
                      const SizedBox(height: 13), // Thursday
                      _dayLabel('Fri'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month Labels Row
                        Row(
                          children: List.generate(weeks, (w) {
                            final hasLabel = monthLabels.containsKey(w);
                            return Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 14, // Added height
                                  child: hasLabel
                                      ? Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              child: Text(
                                                monthLabels[w]!,
                                                softWrap: false,
                                                overflow: TextOverflow.visible,
                                                style: GoogleFonts.inter(
                                                  fontSize: 8,
                                                  color: AppTheme.textMuted,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                if (w < weeks - 1) const SizedBox(width: 3),
                              ],
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        // Grid Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: cells,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Less',
                  style: GoogleFonts.inter(
                      fontSize: 9, color: AppTheme.textMuted)),
              const SizedBox(width: 6),
              ...[0, 1, 2, 3].map((i) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _cellColor(i),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
              const SizedBox(width: 4),
              Text('More',
                  style: GoogleFonts.inter(
                      fontSize: 9, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayLabel(String label) {
    return Container(
      height: 13, // 10 Cell + 3 Spacing
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8,
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _WeightProgressSection extends StatelessWidget {
  final List<WeightLog> weights;
  final Function(double) onUpdate;

  const _WeightProgressSection({required this.weights, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WEIGHT PROGRESS",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Track your transformation",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showUpdateDialog(context),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: AppTheme.accent, size: 20),
                ),
              ),
            ],
          ),
          if (weights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LATEST WEIGHT",
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          weights.last.weight.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "KG",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: weights.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up_rounded, color: AppTheme.textMuted.withOpacity(0.2), size: 40),
                        const SizedBox(height: 8),
                        Text(
                          "No weight logs yet",
                          style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < 0 || value.toInt() >= weights.length) return const SizedBox.shrink();
                              final date = weights[value.toInt()].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "${date.day}/${date.month}",
                                  style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                            reservedSize: 22,
                            interval: (weights.length / 5).clamp(1, weights.length).toDouble(),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: weights.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weight)).toList(),
                          isCurved: true,
                          color: AppTheme.accent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 4,
                              color: AppTheme.accent,
                              strokeWidth: 2,
                              strokeColor: AppTheme.background,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accent.withOpacity(0.2),
                                AppTheme.accent.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppTheme.cardBackground,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                "${spot.y} kg",
                                GoogleFonts.inter(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 12),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppTheme.accent.withOpacity(0.2))),
        title: Text("UPDATE WEIGHT", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter your current weight in kg", style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                hintText: "75.0",
                hintStyle: GoogleFonts.inter(color: AppTheme.textMuted.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.scale_rounded, color: AppTheme.accent, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: GoogleFonts.inter(color: AppTheme.textMuted, fontWeight: FontWeight.w800, fontSize: 12))),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                onUpdate(val);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: Text("SAVE", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
