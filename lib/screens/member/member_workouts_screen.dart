import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

// ── Data Models ────────────────────────────────────────────────────────────────

enum WorkoutPhase { warmup, workout, cooldown }

class Exercise {
  final String name;
  final String sets;
  final String reps;
  final String duration;
  final String gifUrl; // Looping animation URL (GIF via cached_network_image)
  final String muscleGroup;
  final String instructions;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.duration,
    required this.gifUrl,
    required this.muscleGroup,
    required this.instructions,
  });
}

class WorkoutPhaseData {
  final WorkoutPhase phase;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Exercise> exercises;

  const WorkoutPhaseData({
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.exercises,
  });
}

// ── Sample data ────────────────────────────────────────────────────────────────

const _warmupExercises = [
  Exercise(
    name: 'Jumping Jacks',
    sets: '3',
    reps: '30',
    duration: '3 min',
    gifUrl:
        'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExemkwZWxsZmNwanQ4Z3N2MW5wMzNnbm16bnJuN3hhY3hxbXNzNTZmNiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3oEjHSkxqdKLm3kPSM/giphy.gif',
    muscleGroup: 'Full Body',
    instructions: 'Start with feet together. Jump while spreading arms and legs wide. Return to start. Keep a steady rhythm.',
  ),
  Exercise(
    name: 'Arm Circles',
    sets: '2',
    reps: '20',
    duration: '2 min',
    gifUrl:
        'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExeTU5djZ6dWd5aGoxZjBtOGVhbmc1aDFkNmMyYzF3Nmk5czJmeXIwNCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlNQ03J5JxX6lva/giphy.gif',
    muscleGroup: 'Shoulders',
    instructions: 'Extend arms. Make 10 forward circles, then 10 backward. Keep arms straight.',
  ),
  Exercise(
    name: 'High Knees',
    sets: '3',
    reps: '40',
    duration: '3 min',
    gifUrl:
        'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMnh2ZW1sMGhzemhxaXBxOXM3bnZ6dHlka295MWRzcHZuM2xyajJhNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/26HiBuIBhq4prCyCY/giphy.gif',
    muscleGroup: 'Core & Legs',
    instructions: 'Run in place, pulling knees up to hip height. Keep core tight and pump your arms.',
  ),
];

const _workoutExercises = [
  Exercise(
    name: 'Push-Ups',
    sets: '4',
    reps: '15',
    duration: '8 min',
    gifUrl:
        'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOHB0Z2lmMjFheTl0ZTRheHFzeGcwcjU4dGZvdXhzeXFnNXpsbjl5aSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/5t9IfzEhO8EBq/giphy.gif',
    muscleGroup: 'Chest & Triceps',
    instructions: 'Keep body straight, lower chest to floor. Drive through palms back to start. No sagging hips!',
  ),
  Exercise(
    name: 'Squats',
    sets: '4',
    reps: '12',
    duration: '10 min',
    gifUrl:
        'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdjd2Z2JseHRhbW8weTFtcHZnNHNrMzl0MjQ2Z2l6bjdkczhhOW00YiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/f2iPMZBHm4SzxqGnQZ/giphy.gif',
    muscleGroup: 'Quads & Glutes',
    instructions: 'Feet shoulder-width apart. Push hips back and down, keep chest up. Drive through heels to stand.',
  ),
  Exercise(
    name: 'Dumbbell Rows',
    sets: '3',
    reps: '12',
    duration: '9 min',
    gifUrl:
        'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOTBuZXp5a3oxNzVmc2dlM2M5ZDh6b215NWZhbzl3ZGY4dWJlamlyNiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/RH1IFq2GT0Oqm/giphy.gif',
    muscleGroup: 'Back & Biceps',
    instructions: 'Hinge at hip, back flat. Row dumbbell to hip, squeezing shoulder blade. Lower with control.',
  ),
  Exercise(
    name: 'Plank',
    sets: '3',
    reps: '1',
    duration: '5 min',
    gifUrl:
        'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExenl6ZTFhcGp0dTFxaG1oYTl3YTl5eDduOG90aDVuY2FhZWVhZWMyYSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/1n4iuWZFnTeN6qvdpD/giphy.gif',
    muscleGroup: 'Core',
    instructions: 'Forearms on floor, body straight. Hold 30–60s. Squeeze your abs and glutes. No hip drops!',
  ),
];

const _cooldownExercises = [
  Exercise(
    name: 'Child\'s Pose',
    sets: '1',
    reps: '1',
    duration: '2 min',
    gifUrl:
        'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExaHR0bjF5dTRhNXZseXBpbThmZHNlbml1cjV6cjE3ZTFpbmpmMGptaiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/UPBBrXjbhRBrmgpzqj/giphy.gif',
    muscleGroup: 'Back & Hips',
    instructions: 'Kneel, sit back on heels, reach arms forward on floor. Breathe deeply and hold 60–90s.',
  ),
  Exercise(
    name: 'Standing Quad Stretch',
    sets: '2',
    reps: '1',
    duration: '2 min',
    gifUrl:
        'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdzNldjh3ZGV0ZHN6aHppcXVzY3d4dHJwbGt0enByZXM2Ynoxd3VkbCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/7TcdtHOCxo3meUvPgj/giphy.gif',
    muscleGroup: 'Quads',
    instructions: 'Stand on one foot, pull other heel to glutes. Keep knees together. Hold 30s each side.',
  ),
  Exercise(
    name: 'Seated Hamstring Stretch',
    sets: '2',
    reps: '1',
    duration: '2 min',
    gifUrl:
        'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExamlnNjBtd3ptanY4bHpldjF1OWo3Y3Z3dWVlMWVraWVhMXJmeTAxNiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3ohhwJbJPDAXFZHNNS/giphy.gif',
    muscleGroup: 'Hamstrings',
    instructions: 'Sit with legs extended, hinge forward at hips. Reach for feet. Keep back flat. Hold 30s each side.',
  ),
];

final _phases = [
  WorkoutPhaseData(
    phase: WorkoutPhase.warmup,
    title: 'Warmup',
    subtitle: '8 min · Prepare your body',
    icon: Icons.whatshot_rounded,
    color: AppTheme.amber,
    exercises: _warmupExercises,
  ),
  WorkoutPhaseData(
    phase: WorkoutPhase.workout,
    title: 'Workout',
    subtitle: '32 min · Maximum effort',
    icon: Icons.fitness_center_rounded,
    color: AppTheme.accent,
    exercises: _workoutExercises,
  ),
  WorkoutPhaseData(
    phase: WorkoutPhase.cooldown,
    title: 'Cool Down',
    subtitle: '6 min · Recover & stretch',
    icon: Icons.self_improvement_rounded,
    color: AppTheme.blue,
    exercises: _cooldownExercises,
  ),
];

// ── Main Screen ────────────────────────────────────────────────────────────────

class MemberWorkoutsScreen extends StatefulWidget {
  const MemberWorkoutsScreen({super.key});

  @override
  State<MemberWorkoutsScreen> createState() => _MemberWorkoutsScreenState();
}

class _MemberWorkoutsScreenState extends State<MemberWorkoutsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppTheme.cardBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 48), // Padding bottom for tabs
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40), // Space for status bar
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                            fontSize: 32, fontWeight: FontWeight.w900),
                        children: const [
                          TextSpan(
                              text: 'Your ',
                              style: TextStyle(color: Colors.white)),
                          TextSpan(
                              text: 'Workouts',
                              style: TextStyle(color: AppTheme.accent)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Three phases. One unstoppable you.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _PhaseTabBar(controller: _tabCtrl, phases: _phases),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: _phases.map((phase) => _PhaseTabContent(phase: phase)).toList(),
        ),
      ),
    );
  }
}

// ── Tab Bar ────────────────────────────────────────────────────────────────────

class _PhaseTabBar extends StatelessWidget {
  final TabController controller;
  final List<WorkoutPhaseData> phases;

  const _PhaseTabBar({required this.controller, required this.phases});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardBackground,
      child: TabBar(
        controller: controller,
        indicatorColor: phases[controller.index].color,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle:
            GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
        labelColor: phases[controller.index].color,
        unselectedLabelColor: AppTheme.textMuted,
        tabs: phases
            .asMap()
            .entries
            .map(
              (e) => Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(e.value.icon, size: 14),
                    const SizedBox(width: 5),
                    Text(e.value.title.toUpperCase()),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Phase Tab Content ──────────────────────────────────────────────────────────

class _PhaseTabContent extends StatelessWidget {
  final WorkoutPhaseData phase;
  const _PhaseTabContent({required this.phase});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _PhaseHeader(phase: phase),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ExerciseCardWidget(
                  exercise: phase.exercises[i],
                  phaseColor: phase.color,
                  index: i,
                ),
              ),
              childCount: phase.exercises.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ── Phase Hero Header ──────────────────────────────────────────────────────────

class _PhaseHeader extends StatelessWidget {
  final WorkoutPhaseData phase;
  const _PhaseHeader({required this.phase});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            phase.color.withOpacity(0.18),
            phase.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: phase.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: phase.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(phase.icon, color: phase.color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase.title,
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  phase.subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: phase.color),
                ),
                const SizedBox(height: 8),
                Text(
                  '${phase.exercises.length} exercises',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Card Widget ───────────────────────────────────────────────────────

class ExerciseCardWidget extends StatefulWidget {
  final Exercise exercise;
  final Color phaseColor;
  final int index;

  const ExerciseCardWidget({
    super.key,
    required this.exercise,
    required this.phaseColor,
    required this.index,
  });

  @override
  State<ExerciseCardWidget> createState() => _ExerciseCardWidgetState();
}

class _ExerciseCardWidgetState extends State<ExerciseCardWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _expanded
              ? widget.phaseColor.withOpacity(0.4)
              : AppTheme.border,
        ),
        boxShadow: _expanded
            ? [
                BoxShadow(
                    color: widget.phaseColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Card Header (always visible) ────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.transparent,
              child: Row(
                children: [
                  // Index badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.phaseColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: widget.phaseColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + muscle group
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.exercise.muscleGroup,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Quick stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.exercise.sets} × ${widget.exercise.reps}',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: widget.phaseColor),
                      ),
                      Text(
                        widget.exercise.duration,
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Details ─────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ExerciseDetails(
              exercise: widget.exercise,
              phaseColor: widget.phaseColor,
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Details (expanded content with GIF animation) ────────────────────

class _ExerciseDetails extends StatelessWidget {
  final Exercise exercise;
  final Color phaseColor;

  const _ExerciseDetails({required this.exercise, required this.phaseColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0x1AFFFFFF), height: 1),
        // ── GIF Animation ─────────────────────────────────────────────────
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: exercise.gifUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppTheme.cardBackground,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: phaseColor),
                      ),
                      const SizedBox(height: 12),
                      Text('Loading tutorial...',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: AppTheme.cardBackground,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center_rounded,
                          color: phaseColor, size: 48),
                      const SizedBox(height: 8),
                      Text('Animation unavailable',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Stat chips ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              _StatChip(
                  icon: Icons.repeat_rounded,
                  label: '${exercise.sets} Sets',
                  color: phaseColor),
              const SizedBox(width: 8),
              _StatChip(
                  icon: Icons.format_list_numbered_rounded,
                  label: '${exercise.reps} Reps',
                  color: phaseColor),
              const SizedBox(width: 8),
              _StatChip(
                  icon: Icons.timer_outlined,
                  label: exercise.duration,
                  color: phaseColor),
            ],
          ),
        ),

        // ── Instructions ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOW TO DO IT',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.instructions,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
