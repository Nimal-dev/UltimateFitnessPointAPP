import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/diet_provider.dart';
import '../../theme/app_theme.dart';

class MemberDietScreen extends StatefulWidget {
  const MemberDietScreen({super.key});

  @override
  State<MemberDietScreen> createState() => _MemberDietScreenState();
}

class _MemberDietScreenState extends State<MemberDietScreen> {
  final _notesCtrl = TextEditingController();
  bool _savedNotes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<DietProvider>();
      await p.fetchDietData();
      _notesCtrl.text = p.log?.memberNotes ?? '';
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DietProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () => p.fetchDietData(),
        color: AppTheme.accent,
        backgroundColor: AppTheme.cardBackground,
        child: p.isLoading && p.plan == null
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.cardBackground,
                  title: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                      children: const [
                        TextSpan(text: 'MY ', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'DIET', style: TextStyle(color: AppTheme.accent)),
                      ],
                    ),
                  ),
                ),
                if (p.plan == null || p.plan!.id.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.restaurant_menu_rounded,
                                color: AppTheme.textMuted, size: 36),
                          ),
                          const SizedBox(height: 20),
                          Text('No Active Diet Plan',
                              style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Your trainer hasn\'t assigned a diet plan yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Plan Header & Assigned by
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0B0F19),
                                AppTheme.background,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderMid),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Text(
                                      'By ${p.plan!.assignedByName}',
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppTheme.accent.withOpacity(0.2)),
                                    ),
                                    child: Text('Active Plan',
                                        style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: AppTheme.accent,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              RichText(
                                text: TextSpan(
                                    style: GoogleFonts.inter(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900),
                                    children: const [
                                      TextSpan(
                                          text: 'Your ',
                                          style: TextStyle(color: Colors.white)),
                                      TextSpan(
                                          text: 'Nutrition',
                                          style: TextStyle(color: AppTheme.accent)),
                                    ]),
                              ),
                              if (p.plan!.notes.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(p.plan!.notes,
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: AppTheme.textMuted)),
                              ],
                              const SizedBox(height: 20),
                              // Macro strip
                              Row(
                                children: [
                                  _MacroChip(label: 'CAL', value: '${p.plan!.totalCalories}', unit: 'kcal', color: AppTheme.accent),
                                  const SizedBox(width: 8),
                                  _MacroChip(label: 'PROTEIN', value: '${p.plan!.totalProtein}', unit: 'g', color: AppTheme.blue),
                                  const SizedBox(width: 8),
                                  _MacroChip(label: 'CARBS', value: '${p.plan!.totalCarbs}', unit: 'g', color: AppTheme.emerald),
                                  const SizedBox(width: 8),
                                  _MacroChip(label: 'FATS', value: '${p.plan!.totalFats}', unit: 'g', color: AppTheme.orange),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Progress + Water row
                        Row(
                          children: [
                            Expanded(child: _ProgressCard(percent: p.progressPercent, completed: p.log?.mealsCompleted.length ?? 0, total: p.plan!.meals.length)),
                            const SizedBox(width: 16),
                            Expanded(child: _WaterCard(current: p.log?.waterIntake ?? 0, onTap: (g) => p.setWater(g))),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text('DAILY MEALS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: AppTheme.textMuted)),
                        const SizedBox(height: 12),
                        ...p.plan!.meals.map((meal) {
                          final done = p.log?.mealsCompleted.contains(meal.id) ?? false;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: GestureDetector(
                              onTap: () => p.toggleMeal(meal.id),
                              child: _MealCard(meal: meal, isCompleted: done),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),

                        // Daily Journal
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0F19),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderMid),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.edit_note_rounded, color: AppTheme.textMuted, size: 20),
                                    const SizedBox(width: 8),
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Daily Journal', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                      Text('Energy, mood, or cheat meals', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                                    ]),
                                  ]),
                                  GestureDetector(
                                    onTap: () async {
                                      p.updateNotes(_notesCtrl.text);
                                      await p.saveNotes();
                                      setState(() => _savedNotes = true);
                                      Future.delayed(const Duration(seconds: 2),
                                          () => setState(() => _savedNotes = false));
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _savedNotes
                                            ? AppTheme.green.withOpacity(0.15)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _savedNotes
                                              ? AppTheme.green.withOpacity(0.3)
                                              : AppTheme.border,
                                        ),
                                      ),
                                      child: Text(
                                        _savedNotes ? 'Saved!' : 'Save',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _savedNotes ? AppTheme.green : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _notesCtrl,
                                maxLines: 4,
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'E.g., Felt great today, had extra protein...',
                                  fillColor: Colors.black.withOpacity(0.5),
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
}

class _MacroChip extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _MacroChip({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 8, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(unit, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int percent, completed, total;
  const _ProgressCard({required this.percent, required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text("TODAY'S PROGRESS", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 80, height: 80,
              child: CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: AppTheme.accent,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$percent%', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('EATEN', style: GoogleFonts.inter(fontSize: 8, color: AppTheme.textMuted, letterSpacing: 1)),
            ]),
          ]),
          const SizedBox(height: 12),
          Text('$completed / $total meals', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final int current;
  final Function(int) onTap;
  const _WaterCard({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('HYDRATION', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppTheme.blue)),
            const Icon(Icons.water_drop_rounded, color: AppTheme.blue, size: 18),
          ]),
          const SizedBox(height: 4),
          Text('$current / 8 Glasses', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(8, (i) {
              final g = i + 1;
              final filled = current >= g;
              return GestureDetector(
                onTap: () => onTap(g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30, height: 34,
                  decoration: BoxDecoration(
                    gradient: filled
                        ? const LinearGradient(colors: [Color(0xFF2563EB), AppTheme.blue], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                        : null,
                    color: filled ? null : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: filled ? AppTheme.blue : AppTheme.border),
                  ),
                  child: Icon(Icons.water_drop_rounded, size: 14, color: filled ? Colors.white : AppTheme.textMuted),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final dynamic meal;
  final bool isCompleted;
  const _MealCard({required this.meal, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? AppTheme.accent.withOpacity(0.3) : AppTheme.border,
        ),
        boxShadow: isCompleted
            ? [BoxShadow(color: AppTheme.accent.withOpacity(0.05), blurRadius: 20)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(meal.timeOfDay, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppTheme.accent)),
                Text(meal.time, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.accent : Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: isCompleted ? AppTheme.accent : AppTheme.border),
                ),
                child: Icon(Icons.check_rounded, size: 16, color: isCompleted ? AppTheme.charcoal : Colors.transparent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...meal.items.map<Widget>((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Container(width: 5, height: 5, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(item, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                ]),
              )),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _Badge('⚡ ${meal.calories} kcal', Colors.white.withOpacity(0.05), AppTheme.textMuted),
            _Badge('P: ${meal.protein}g', AppTheme.blue.withOpacity(0.1), AppTheme.blue),
            _Badge('C: ${meal.carbs}g', AppTheme.emerald.withOpacity(0.1), AppTheme.emerald),
            _Badge('F: ${meal.fats}g', AppTheme.orange.withOpacity(0.1), AppTheme.orange),
          ]),
        ],
      ),
    );
  }
}

Widget _Badge(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
    );
