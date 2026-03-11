import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/member_provider.dart';
import 'providers/diet_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/owner_provider.dart';
import 'services/api_service.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'dart:io' show Platform;

import 'screens/login_screen.dart';
import 'screens/shared/force_mpin_reset_screen.dart';
import 'screens/member/member_dashboard_screen.dart';
import 'screens/member/member_diet_screen.dart';
import 'screens/member/member_workouts_screen.dart';
import 'screens/owner/owner_dashboard_screen.dart';
import 'screens/owner/owner_members_screen.dart';
import 'screens/owner/owner_trainers_screen.dart';
import 'screens/trainer/trainer_dashboard_screen.dart';
import 'screens/trainer/trainer_clients_screen.dart';
import 'screens/shared/splash_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Start 14-minute self-ping to keep Render free tier alive
  Timer.periodic(const Duration(minutes: 14), (_) => ApiService.ping());
  
  // Set high refresh rate for smooth scrolling on Android
  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {
      // Ignore if not supported
    }
  }
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => DietProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => OwnerProvider()),
      ],
      child: const UltimateGymApp(),
    ),
  );
}

class UltimateGymApp extends StatelessWidget {
  const UltimateGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultimate Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _splashDone = false;
  // Tracks whether the initial auto-login check has finished at least once.
  // After this is true we never use auth.isLoading to gate the UI — that
  // prevents user-triggered login calls from bouncing back to the splash.
  bool _initialAuthDone = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Mark the initial auth check as complete the first time isLoading is false.
    if (!_initialAuthDone && !auth.isLoading) {
      // Use a post-frame callback so we don't call setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_initialAuthDone) setState(() => _initialAuthDone = true);
      });
    }

    // Show splash until both the animation AND the initial check are done.
    if (!_splashDone || !_initialAuthDone) {
      return AnimatedSplashScreen(
        onFinish: () {
          if (mounted) setState(() => _splashDone = true);
        },
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // Gate: force MPIN reset for first-time logins with default 0000
    if (auth.needsMpinReset) {
      return const ForceMpinResetScreen();
    }

    final role = auth.user!.role;
    if (role == 'Member') return const MemberShell();
    if (role == 'Trainer') return const TrainerShell();
    return const OwnerShell();
  }
}

// Splash removed - replaced by AnimatedSplashScreen from shared/splash_screen.dart

// ─── Member Shell ─────────────────────────────────────────────────────────────

class MemberShell extends StatefulWidget {
  const MemberShell({super.key});

  @override
  State<MemberShell> createState() => _MemberShellState();
}

class _MemberShellState extends State<MemberShell> {
  int _idx = 0;

  static const _screens = [
    MemberDashboardScreen(),
    MemberWorkoutsScreen(),
    MemberDietScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _BottomNav(
        index: _idx,
        items: const [
          BottomNavItem(icon: Icons.emoji_events_rounded, label: 'Status'),
          BottomNavItem(icon: Icons.fitness_center_rounded, label: 'Workouts'),
          BottomNavItem(icon: Icons.restaurant_menu_rounded, label: 'Diet'),
        ],
        onTap: (i) => setState(() => _idx = i),
        onLogout: () => context.read<AuthProvider>().logout(),
      ),
    );
  }
}

// ─── Owner Shell ──────────────────────────────────────────────────────────────

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _idx = 0;

  static const _screens = [
    OwnerDashboardScreen(),
    OwnerMembersScreen(),
    OwnerTrainersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _BottomNav(
        index: _idx,
        items: const [
          BottomNavItem(icon: Icons.dashboard_rounded, label: 'Overview'),
          BottomNavItem(icon: Icons.group_rounded, label: 'Members'),
          BottomNavItem(icon: Icons.psychology_rounded, label: 'Trainers'),
        ],
        onTap: (i) => setState(() => _idx = i),
        onLogout: () => context.read<AuthProvider>().logout(),
      ),
    );
  }
}

// ─── Trainer Shell ────────────────────────────────────────────────────────────

class TrainerShell extends StatefulWidget {
  const TrainerShell({super.key});

  @override
  State<TrainerShell> createState() => _TrainerShellState();
}

class _TrainerShellState extends State<TrainerShell> {
  int _idx = 0;

  static const _screens = [
    TrainerDashboardScreen(),
    TrainerClientsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _BottomNav(
        index: _idx,
        items: const [
          BottomNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
          BottomNavItem(icon: Icons.people_rounded, label: 'Clients'),
        ],
        onTap: (i) => setState(() => _idx = i),
        onLogout: () => context.read<AuthProvider>().logout(),
      ),
    );
  }
}

// ─── Shared Bottom Nav ────────────────────────────────────────────────────────

class BottomNavItem {
  final IconData icon;
  final String label;
  const BottomNavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int index;
  final List<BottomNavItem> items;
  final Function(int) onTap;
  final VoidCallback onLogout;

  const _BottomNav({
    required this.index,
    required this.items,
    required this.onTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = [...items, const BottomNavItem(icon: Icons.logout_rounded, label: 'Logout')];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(allItems.length, (i) {
              final isLogout = i == allItems.length - 1;
              final selected = !isLogout && i == index;
              return Expanded(
                child: GestureDetector(
                  onTap: isLogout ? onLogout : () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.accent.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          allItems[i].icon,
                          size: 22,
                          color: isLogout
                              ? AppTheme.red
                              : selected
                                  ? AppTheme.accent
                                  : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        allItems[i].label,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isLogout
                              ? AppTheme.red
                              : selected
                                  ? AppTheme.accent
                                  : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
