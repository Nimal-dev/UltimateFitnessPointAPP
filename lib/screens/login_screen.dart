import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';

enum _LoginStep { mobile, mpin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  _LoginStep _step = _LoginStep.mobile;
  final _mobileCtrl = TextEditingController();
  String _mpin = '';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  void _goToMpin() {
    final mobile = _mobileCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (mobile.length < 10) {
      SnackbarUtils.showError(context,
          'Enter a valid 10-digit mobile number to get started!');
      return;
    }
    setState(() {
      _step = _LoginStep.mpin;
      _mpin = '';
    });
    _fadeCtrl.forward(from: 0);
  }

  void _onKeyTap(String digit) {
    if (_mpin.length < 4) {
      setState(() => _mpin += digit);
      if (_mpin.length == 4) {
        _doLogin();
      }
    }
  }

  void _onBackspace() {
    if (_mpin.isNotEmpty) {
      setState(() => _mpin = _mpin.substring(0, _mpin.length - 1));
    }
  }

  Future<void> _doLogin() async {
    final mobile = _mobileCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(mobile, _mpin);
    if (!ok && mounted) {
      setState(() => _mpin = '');
      SnackbarUtils.showError(
          context, auth.error ?? 'MPIN incorrect. Please try again!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _step == _LoginStep.mobile
              ? _MobileStep(
                  controller: _mobileCtrl,
                  onNext: _goToMpin,
                )
              : _MpinStep(
                  mobile: _mobileCtrl.text,
                  mpin: _mpin,
                  isLoading: auth.isLoading,
                  onKeyTap: _onKeyTap,
                  onBackspace: _onBackspace,
                  onBack: () {
                    setState(() {
                      _step = _LoginStep.mobile;
                      _mpin = '';
                    });
                    _fadeCtrl.forward(from: 0);
                  },
                ),
        ),
      ),
    );
  }
}

// ── Step 1: Mobile number entry ───────────────────────────────────────────────
class _MobileStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;
  const _MobileStep({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          // Logo
          Center(
            child: Column(children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 36,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    color: AppTheme.charcoal, size: 38),
              ),
              const SizedBox(height: 18),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900),
                  children: const [
                    TextSpan(text: 'ULTIMATE', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'GYM', style: TextStyle(color: AppTheme.accent)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text('MEMBER PORTAL', style: GoogleFonts.inter(fontSize: 10, letterSpacing: 4, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 52),
          Text('Enter your mobile', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 6),
          Text('We\'ll verify with your 4-digit MPIN', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 32),
          _label('MOBILE NUMBER'),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            autofocus: true,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: '9876543210',
              hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 16, letterSpacing: 2),
              prefixIcon: const Icon(Icons.phone_android_rounded, color: AppTheme.textMuted, size: 20),
              counterText: '',
            ),
            maxLength: 15,
            onSubmitted: (_) => onNext(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onNext,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('CONTINUE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('Don\'t have an account? Contact your gym owner.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: MPIN PIN-pad ──────────────────────────────────────────────────────
class _MpinStep extends StatelessWidget {
  final String mobile, mpin;
  final bool isLoading;
  final Function(String) onKeyTap;
  final VoidCallback onBackspace, onBack;

  const _MpinStep({
    required this.mobile,
    required this.mpin,
    required this.isLoading,
    required this.onKeyTap,
    required this.onBackspace,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
          ),
        ),
        const Spacer(flex: 1),
        // Logo micro
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withValues(alpha: 0.35), blurRadius: 28),
            ],
          ),
          child: const Icon(Icons.lock_outline_rounded, color: AppTheme.charcoal, size: 28),
        ),
        const SizedBox(height: 24),
        Text('Enter your MPIN', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 6),
        Text(
          '+91 ${mobile.length > 5 ? "•••••${mobile.substring(mobile.length - 5)}" : mobile}',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.accent, fontWeight: FontWeight.w700, letterSpacing: 2),
        ),
        const SizedBox(height: 40),

        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < mpin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppTheme.accent : Colors.transparent,
                border: Border.all(
                  color: filled ? AppTheme.accent : AppTheme.borderMid,
                  width: 2,
                ),
                boxShadow: filled
                    ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.5), blurRadius: 12)]
                    : [],
              ),
            );
          }),
        ),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
            ),
          ),
        const Spacer(flex: 2),

        // PIN pad
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              _PinRow(['1', '2', '3'], onKeyTap: onKeyTap),
              const SizedBox(height: 16),
              _PinRow(['4', '5', '6'], onKeyTap: onKeyTap),
              const SizedBox(height: 16),
              _PinRow(['7', '8', '9'], onKeyTap: onKeyTap),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Empty placeholder
                  const SizedBox(width: 72, height: 72),
                  _PinKey('0', onTap: () => onKeyTap('0')),
                  _BackspaceKey(onTap: onBackspace),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _PinRow extends StatelessWidget {
  final List<String> digits;
  final Function(String) onKeyTap;
  const _PinRow(this.digits, {required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _PinKey(d, onTap: () => onKeyTap(d))).toList(),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  const _PinKey(this.digit, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderMid),
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  final VoidCallback onTap;
  const _BackspaceKey({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.backspace_outlined, color: AppTheme.textSecondary, size: 24),
        ),
      ),
    );
  }
}

Widget _label(String text) => Text(
      text,
      style: GoogleFonts.inter(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
    );
