import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'membership_renewal_screen.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              color: AppTheme.accent,
              backgroundColor: AppTheme.cardBackground,
              onRefresh: () =>
                  provider.fetchDashboard(year: _selectedYear),
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
                        padding: const EdgeInsets.only(right: 16),
                        child: Container(
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
                        const SizedBox(height: 28),

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

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
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

  @override
  Widget build(BuildContext context) {
    // Build 52-week grid
    DateTime start = DateTime(year, 1, 1);
    // Start on Sunday
    start = start.subtract(Duration(days: start.weekday % 7));
    const weeks = 53;
    final cells = <Widget>[];

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cells,
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
}
