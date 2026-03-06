import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';

/// A full-screen diet plan editor used by both Owner and Trainer.
/// Pass [memberId] and [memberName] to assign to a specific member.
class DietPlanEditorScreen extends StatefulWidget {
  final String memberId;
  final String memberName;

  const DietPlanEditorScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<DietPlanEditorScreen> createState() => _DietPlanEditorScreenState();
}

class _DietPlanEditorScreenState extends State<DietPlanEditorScreen> {
  final _notesCtrl = TextEditingController();
  final List<_MealForm> _meals = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _meals.add(_MealForm()); // start with one meal
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final m in _meals) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _assignPlan() async {
    // Validate — every meal needs a time label
    for (int i = 0; i < _meals.length; i++) {
      if (_meals[i].timeOfDay.trim().isEmpty) {
        SnackbarUtils.showError(context,
            'Meal ${i + 1}: please give it a name (e.g. Breakfast) before assigning!');
        return;
      }
    }

    setState(() => _isSaving = true);

    final mealPayload = _meals.map((m) => m.toJson()).toList();
    final p = context.read<OwnerProvider>();
    final ok = await p.assignDietPlan(widget.memberId, mealPayload, _notesCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      SnackbarUtils.showSuccess(context,
          'Diet plan locked in for ${widget.memberName}! They\'re gonna crush it! 💪');
      Navigator.pop(context, true);
    } else {
      SnackbarUtils.showError(context,
          'Whoops, dropped the dumbbell! Failed to assign diet plan. Try again.');
    }
  }

  void _addMeal() {
    setState(() => _meals.add(_MealForm()));
  }

  void _removeMeal(int index) {
    setState(() {
      _meals[index].dispose();
      _meals.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                children: const [
                  TextSpan(text: 'DIET ', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'PLAN', style: TextStyle(color: AppTheme.accent)),
                ],
              ),
            ),
            Text(
              'For ${widget.memberName}',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _isSaving
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                  )
                : TextButton(
                    onPressed: _assignPlan,
                    child: Text('ASSIGN',
                        style: GoogleFonts.inter(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1)),
                  ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Summary macro bar (live totals)
          SliverToBoxAdapter(child: _MacroSummaryBar(meals: _meals)),

          // Notes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SectionHeader('PLAN NOTES', Icons.notes_rounded),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Hydration goals, timing notes, dietary restrictions...',
                ),
              ),
            ),
          ),

          // Meal list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionHeader('MEALS (${_meals.length})', Icons.restaurant_rounded),
                  GestureDetector(
                    onTap: _addMeal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add_rounded, color: AppTheme.accent, size: 16),
                        const SizedBox(width: 6),
                        Text('ADD MEAL',
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accent, letterSpacing: 0.5)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Meal cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _MealCard(
                    form: _meals[i],
                    index: i,
                    canDelete: _meals.length > 1,
                    onDelete: () => _removeMeal(i),
                    onChanged: () => setState(() {}), // refresh macro bar
                  ),
                ),
                childCount: _meals.length,
              ),
            ),
          ),

          // Bottom assign button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _assignPlan,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.charcoal),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'ASSIGN DIET PLAN',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live macro summary bar at the top ─────────────────────────────────────────
class _MacroSummaryBar extends StatelessWidget {
  final List<_MealForm> meals;
  const _MacroSummaryBar({required this.meals});

  int _sum(int Function(_MealForm) f) => meals.fold(0, (s, m) => s + f(m));

  @override
  Widget build(BuildContext context) {
    final cal = _sum((m) => m.calories);
    final pro = _sum((m) => m.protein);
    final car = _sum((m) => m.carbs);
    final fat = _sum((m) => m.fats);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderMid),
      ),
      child: Row(
        children: [
          Expanded(child: _MacroTile('CALORIES', '$cal', 'kcal', AppTheme.accent)),
          _divider(),
          Expanded(child: _MacroTile('PROTEIN', '${pro}g', 'total', AppTheme.blue)),
          _divider(),
          Expanded(child: _MacroTile('CARBS', '${car}g', 'total', AppTheme.emerald)),
          _divider(),
          Expanded(child: _MacroTile('FATS', '${fat}g', 'total', AppTheme.orange)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppTheme.border,
      );
}

class _MacroTile extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _MacroTile(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: GoogleFonts.inter(fontSize: 8, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
      const SizedBox(height: 3),
      Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      Text(unit, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted)),
    ]);
  }
}

// ── Individual meal card ───────────────────────────────────────────────────────
class _MealCard extends StatefulWidget {
  final _MealForm form;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete, onChanged;

  const _MealCard({
    required this.form,
    required this.index,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard> {
  bool _expanded = true;

  static const _timeSlots = [
    'Breakfast', 'Morning Snack', 'Lunch',
    'Evening Snack', 'Pre-Workout', 'Post-Workout', 'Dinner', 'Late Night',
  ];

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final Color accentColor = _mealColor(widget.index);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _expanded ? accentColor.withValues(alpha: 0.25) : AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          // Header row — always visible
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        form.timeOfDay.isEmpty ? 'New Meal' : form.timeOfDay,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        form.time.isEmpty ? 'Tap to set time & items' : form.time,
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ]),
                  ),
                  // Macro summary badges
                  if (!_expanded) ...[
                    _smallBadge('${form.calories} kcal', AppTheme.accent),
                    const SizedBox(width: 6),
                  ],
                  if (widget.canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.red, size: 18),
                      onPressed: widget.onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expandable body
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _MealFormBody(
              form: form,
              timeSlots: _timeSlots,
              onChanged: () {
                setState(() {});
                widget.onChanged();
              },
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Color _mealColor(int i) {
    const colors = [
      AppTheme.accent, AppTheme.blue, AppTheme.emerald,
      AppTheme.orange, AppTheme.purple, AppTheme.red,
      AppTheme.amber, AppTheme.green,
    ];
    return colors[i % colors.length];
  }

  Widget _smallBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: GoogleFonts.inter(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
      );
}

// ── Form fields inside a meal card ────────────────────────────────────────────
class _MealFormBody extends StatelessWidget {
  final _MealForm form;
  final List<String> timeSlots;
  final VoidCallback onChanged;

  const _MealFormBody({
    required this.form,
    required this.timeSlots,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 14),

          // Meal name + time on same row
          Row(children: [
            Expanded(
              flex: 3,
              child: _fieldGroup(
                'MEAL TYPE',
                DropdownButtonFormField<String>(
                  value: timeSlots.contains(form.timeOfDay) ? form.timeOfDay : null,
                  dropdownColor: const Color(0xFF111111),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: _inputDec('e.g. Breakfast'),
                  items: timeSlots
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      form.timeOfDay = v;
                      onChanged();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _fieldGroup(
                'TIME',
                TextFormField(
                  initialValue: form.time,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: _inputDec('08:00'),
                  onChanged: (v) { form.time = v; onChanged(); },
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Food items
          _fieldGroup(
            'FOOD ITEMS  (one per line or comma-separated)',
            TextFormField(
              initialValue: form.itemsRaw,
              maxLines: 3,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: _inputDec('Oats 50g, 2 Eggs\nBanana'),
              onChanged: (v) { form.itemsRaw = v; onChanged(); },
            ),
          ),
          const SizedBox(height: 12),

          // Instructions
          _fieldGroup(
            'INSTRUCTIONS (optional)',
            TextFormField(
              initialValue: form.instructions,
              maxLines: 2,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: _inputDec('E.g. Cook oats in water, not milk...'),
              onChanged: (v) { form.instructions = v; onChanged(); },
            ),
          ),
          const SizedBox(height: 16),

          // Macros
          Text('MACROS', style: GoogleFonts.inter(fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _MacroField('Calories', 'kcal', AppTheme.accent, form.calories, (v) { form.calories = v; onChanged(); })),
            const SizedBox(width: 8),
            Expanded(child: _MacroField('Protein', 'g', AppTheme.blue, form.protein, (v) { form.protein = v; onChanged(); })),
            const SizedBox(width: 8),
            Expanded(child: _MacroField('Carbs', 'g', AppTheme.emerald, form.carbs, (v) { form.carbs = v; onChanged(); })),
            const SizedBox(width: 8),
            Expanded(child: _MacroField('Fats', 'g', AppTheme.orange, form.fats, (v) { form.fats = v; onChanged(); })),
          ]),
        ],
      ),
    );
  }

  Widget _fieldGroup(String label, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          child,
        ],
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
        fillColor: Colors.black.withValues(alpha: 0.5),
        filled: true,
      );
}

class _MacroField extends StatelessWidget {
  final String label, unit;
  final Color color;
  final int value;
  final Function(int) onChanged;

  const _MacroField(this.label, this.unit, this.color, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: TextFormField(
            initialValue: value == 0 ? '' : '$value',
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.inter(color: color.withValues(alpha: 0.4), fontSize: 16, fontWeight: FontWeight.w900),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '$label ($unit)',
            style: GoogleFonts.inter(fontSize: 8, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }
}

Widget _SectionHeader(String text, IconData icon) => Row(children: [
      Icon(icon, color: AppTheme.textMuted, size: 14),
      const SizedBox(width: 6),
      Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppTheme.textMuted)),
    ]);

// ── Plain data class per meal ──────────────────────────────────────────────────
class _MealForm {
  String timeOfDay = '';
  String time = '';
  String itemsRaw = '';
  String instructions = '';
  int calories = 0;
  int protein = 0;
  int carbs = 0;
  int fats = 0;

  void dispose() {} // for future resource cleanup if needed

  List<String> get items => itemsRaw
      .split(RegExp(r'[,\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Map<String, dynamic> toJson() => {
        'timeOfDay': timeOfDay,
        'time': time,
        'items': items,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'instructions': instructions,
      };
}
