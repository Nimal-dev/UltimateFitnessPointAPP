import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/analytics_model.dart';
import '../../models/member_model.dart';
import '../../providers/owner_provider.dart';
import '../../providers/member_provider.dart';
import '../../models/fitness_log_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/strength_log_dialog.dart';

import '../../providers/auth_provider.dart';

class MemberAnalyticsScreen extends StatefulWidget {
  final MemberModel member;
  const MemberAnalyticsScreen({super.key, required this.member});

  @override
  State<MemberAnalyticsScreen> createState() => _MemberAnalyticsScreenState();
}

class _MemberAnalyticsScreenState extends State<MemberAnalyticsScreen> {
  MemberAnalytics? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final isOwner = auth.user?.role == 'Owner' || auth.user?.role == 'Trainer';
    
    MemberAnalytics? analytics;
    
    if (isOwner) {
      analytics = await context.read<OwnerProvider>().fetchMemberAnalytics(widget.member.id);
    } else {
      analytics = await context.read<MemberProvider>().fetchAnalytics();
      await context.read<MemberProvider>().fetchStrengthLogs();
    }
    
    if (mounted) {
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member Analytics', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(widget.member.name, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.accent)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _analytics == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          context.read<OwnerProvider>().error ?? 'Failed to load analytics',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _loadData();
                          },
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileSection(),
                      const SizedBox(height: 24),
                      _buildSummaryGrid(),
                      const SizedBox(height: 24),
                      _buildHealthMetricsSection(),
                      const SizedBox(height: 24),
                      _buildChartCard('Workout Completion (%)', _buildWorkoutChart()),
                      const SizedBox(height: 16),
                      _buildChartCard('Diet Adherence (%)', _buildDietChart()),
                      const SizedBox(height: 16),
                       _buildChartCard('Water Intake (Glasses)', _buildWaterChart()),
                      const SizedBox(height: 24),
                      _buildStrengthSection(),
                      const SizedBox(height: 24),
                      _buildAttendanceSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showStrengthDialog,
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.fitness_center_rounded, color: Colors.black),
      ),
    );
  }

  void _showStrengthDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const StrengthLogDialog(),
    );

    if (result != null && mounted) {
      final newLog = OneRepMaxLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseName: result['exercise'],
        weight: result['weight'],
        date: DateTime.now(),
      );
      context.read<MemberProvider>().addStrengthLog(newLog);
    }
  }

  Widget _buildStrengthSection() {
    return Consumer<MemberProvider>(
      builder: (context, provider, child) {
        final logs = provider.strengthLogs;
        if (logs.isEmpty) {
          return _buildEmptyStrengthState();
        }

        // Group logs by exercise name
        final Map<String, List<OneRepMaxLog>> groupedLogs = {};
        for (var log in logs) {
          groupedLogs.putIfAbsent(log.exerciseName, () => []).add(log);
        }

        // Sort each group by date (newest first)
        for (var exercise in groupedLogs.keys) {
          groupedLogs[exercise]!.sort((a, b) => b.date.compareTo(a.date));
        }

        final exerciseNames = groupedLogs.keys.toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STRENGTH PROGRESS (1RM)',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
            const SizedBox(height: 16),
            ...exerciseNames.map((name) => _buildExerciseMasterCard(name, groupedLogs[name]!)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyStrengthState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STRENGTH PROGRESS (1RM)',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Center(
            child: Text(
              'No strength logs yet',
              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseMasterCard(String name, List<OneRepMaxLog> history) {
    final lastLog = history.first;
    final prevLog = history.length > 1 ? history[1] : null;
    final diff = prevLog != null ? lastLog.weight - prevLog.weight : 0.0;
    final maxWeight = history.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final isNewPR = lastLog.weight >= maxWeight;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isNewPR ? AppTheme.accent.withOpacity(0.3) : AppTheme.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isNewPR ? AppTheme.accent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 16,
                  color: isNewPR ? AppTheme.accent : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                    if (isNewPR)
                      Text('PERSONAL RECORD',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.accent)),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8, left: 36),
            child: Row(
              children: [
                Text('${lastLog.weight}',
                    style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w900, color: isNewPR ? AppTheme.accent : Colors.white)),
                const SizedBox(width: 4),
                Text('kg',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                if (diff != 0) ...[
                  const SizedBox(width: 12),
                  Icon(
                    diff > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 14,
                    color: diff > 0 ? AppTheme.emerald : AppTheme.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: diff > 0 ? AppTheme.emerald : AppTheme.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(color: AppTheme.border, height: 24),
            ...history.map((h) => _buildHistoryRow(h, h == history.first)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(OneRepMaxLog log, bool isLatest) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isLatest ? AppTheme.accent : AppTheme.textMuted.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${log.date.day} ${_getMonthName(log.date.month)} ${log.date.year}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isLatest ? Colors.white : Colors.white60,
                  fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            '${log.weight} kg',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isLatest ? AppTheme.accent : Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildProfileSection() {
    final user = _analytics?.memberProfile;
    if (user == null) return const SizedBox();

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
          Text('PERSONAL PROFILE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.accent, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _profileRow(Icons.phone_iphone_rounded, 'Mobile', user.mobile ?? widget.member.mobile),
          const SizedBox(height: 12),
          _profileRow(Icons.email_outlined, 'Email', user.email.isNotEmpty ? user.email : widget.member.email),
          const SizedBox(height: 12),
          _profileRow(Icons.calendar_month_rounded, 'Joined', widget.member.joined),
          const SizedBox(height: 12),
          _profileRow(Icons.verified_user_outlined, 'Status', widget.member.status.toUpperCase(), 
            color: widget.member.status == 'Active' ? AppTheme.emerald : AppTheme.amber),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Text('$label:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(width: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? Colors.white)),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    final s = _analytics!.summary;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _summaryCard('Attendance', '${s.attendanceDays}', '/ 30 days', AppTheme.accent),
        _summaryCard('Avg Water', '${s.avgWater}', 'glasses/day', AppTheme.blue),
        _summaryCard('Diet Adherence', s.avgDietAdherence != null ? '${s.avgDietAdherence}%' : 'N/A', 'last 7 days', AppTheme.emerald),
        _summaryCard('Total Points', '${s.totalPoints}', 'career points', AppTheme.amber),
      ],
    );
  }

  Widget _summaryCard(String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(width: 4),
              Text(unit, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricsSection() {
    final user = _analytics?.memberProfile;
    if (user == null || user.weight == null || user.height == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.amber, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('Physical metrics (weight/height) not updated for this member.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted))),
          ],
        ),
      );
    }

    final bmi = user.bmi ?? 0;
    final category = user.bmiCategory;
    final color = user.bmiColor;
    final bmr = user.bmr;
    final tdee = user.tdee;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('BODY MASS INDEX', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(category.toUpperCase(), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
                    child: Text(bmi.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(height: 6, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), gradient: const LinearGradient(colors: [Colors.blue, Color(0xFFD4E600), Colors.orange, Colors.red]))),
                  Align(
                    alignment: Alignment((((bmi.clamp(15, 35) - 15) / 20) * 2) - 1, 0),
                    child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppTheme.background, width: 2))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _bmiSmallLabel('18.5', 'Under'),
                _bmiSmallLabel('24.9', 'Healthy'),
                _bmiSmallLabel('29.9', 'Over'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PHYSICAL STATS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statItem('Weight', '${user.weight} kg', Icons.monitor_weight_outlined),
                  const SizedBox(width: 24),
                  _statItem('Height', '${user.height} cm', Icons.height_rounded),
                ],
              ),
              const Divider(height: 32, color: AppTheme.border),
              Row(
                children: [
                  _statItem('BMR (Basal)', bmr != null ? '${bmr.round()} kcal' : 'N/A', Icons.speed_rounded, color: AppTheme.accent),
                  const SizedBox(width: 24),
                  _statItem('TDEE (Daily Burn)', tdee != null ? '${tdee.round()} kcal' : 'N/A', Icons.local_fire_department_rounded, color: AppTheme.red),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bmiSmallLabel(String val, String text) => Column(children: [
    Text(val, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
    Text(text, style: GoogleFonts.inter(fontSize: 7, color: AppTheme.textMuted)),
  ]);

  Widget _statItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: color ?? Colors.white)),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
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
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 24),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildWorkoutChart() {
    final spots = _analytics!.workoutTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.completionPercent.toDouble());
    }).toList();
    return _baseLineChart(spots, AppTheme.accent);
  }

  Widget _buildDietChart() {
    final spots = _analytics!.dietTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.adherencePercent.toDouble());
    }).toList();
    return _baseLineChart(spots, AppTheme.emerald);
  }

  Widget _buildWaterChart() {
    final spots = _analytics!.dietTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.waterIntake.toDouble());
    }).toList();
    return _baseLineChart(spots, AppTheme.blue, maxY: 10);
  }

  Widget _baseLineChart(List<FlSpot> spots, Color color, {double maxY = 100}) {
    if (spots.isEmpty) return const Center(child: Text('Not enough data', style: TextStyle(color: AppTheme.textMuted)));
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4, getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)))),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            int idx = v.toInt();
            if (idx < 0 || idx >= _analytics!.dietTrend.length) return const SizedBox();
            final date = _analytics!.dietTrend[idx].date;
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('${date.day}/${date.month}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
            );
          })),
        ),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: (spots.length - 1).toDouble(),
        minY: 0, maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendance (last 30 days)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _analytics!.attendance.map((a) {
            return Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: a.present ? AppTheme.accent : Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
