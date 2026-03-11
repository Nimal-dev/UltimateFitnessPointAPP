import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';

class ForceMpinResetScreen extends StatefulWidget {
  const ForceMpinResetScreen({super.key});

  @override
  State<ForceMpinResetScreen> createState() => _ForceMpinResetScreenState();
}

class _ForceMpinResetScreenState extends State<ForceMpinResetScreen>
    with SingleTickerProviderStateMixin {
  // Phase 0 = enter new MPIN, Phase 1 = confirm MPIN
  int _phase = 0;
  String _newMpin = '';
  String _confirmMpin = '';

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _currentPin => _phase == 0 ? _newMpin : _confirmMpin;

  void _onKeyTap(String digit) {
    if (_currentPin.length < 4) {
      setState(() {
        if (_phase == 0) {
          _newMpin += digit;
        } else {
          _confirmMpin += digit;
        }
      });

      if (_currentPin.length == 4) {
        _onPinComplete();
      }
    }
  }

  void _onBackspace() {
    if (_currentPin.isNotEmpty) {
      setState(() {
        if (_phase == 0) {
          _newMpin = _newMpin.substring(0, _newMpin.length - 1);
        } else {
          _confirmMpin = _confirmMpin.substring(0, _confirmMpin.length - 1);
        }
      });
    }
  }

  Future<void> _onPinComplete() async {
    if (_phase == 0) {
      if (_newMpin == '0000') {
        SnackbarUtils.showError(context,
            'Your new MPIN cannot be 0000. Level up your security game!');
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() => _newMpin = '');
        return;
      }
      // Advance to confirmation phase
      setState(() => _phase = 1);
    } else {
      // Confirm phase complete — check if they match
      if (_confirmMpin != _newMpin) {
        _shakeCtrl.forward(from: 0);
        SnackbarUtils.showError(context,
            'MPINs don\'t match. No pain, no gain — try again!');
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _phase = 0;
          _newMpin = '';
          _confirmMpin = '';
        });
        return;
      }
      // Both match — call save
      await _saveNewMpin();
    }
  }

  Future<void> _saveNewMpin() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetMpin(_newMpin);
    if (!ok && mounted) {
      SnackbarUtils.showError(
          context, auth.error ?? 'MPIN reset failed. Give it another rep!');
      setState(() {
        _phase = 0;
        _newMpin = '';
        _confirmMpin = '';
      });
    }
    // On success, AuthProvider clears needsMpinReset → _AuthGate navigates to home
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 44),
            _buildHeader(),
            const Spacer(flex: 1),
            _buildPhaseIndicator(),
            const SizedBox(height: 40),
            _buildPinDots(),
            if (auth.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.accent),
                ),
              ),
            const Spacer(flex: 2),
            _buildKeypad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.amber.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.amber.withOpacity(0.5), width: 2),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: AppTheme.amber,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _phase == 0 ? 'Set Your New MPIN' : 'Confirm Your MPIN',
          style: GoogleFonts.inter(
              fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          _phase == 0
              ? 'Your default PIN has been reset.\nChoose a strong 4-digit code — not 0000!'
              : 'Re-enter your new MPIN to confirm.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildPhaseIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final isActive = i <= _phase;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 32 : 14,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accent : AppTheme.borderMid,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final offset = _phase == 1
            ? Offset(10 * (_shakeAnim.value % 0.5 < 0.25 ? 1 : -1), 0)
            : Offset.zero;
        return Transform.translate(offset: offset, child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          final filled = i < _currentPin.length;
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
                  ? [BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 12)]
                  : [],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _PinRow(['1', '2', '3'], onKeyTap: _onKeyTap),
          const SizedBox(height: 16),
          _PinRow(['4', '5', '6'], onKeyTap: _onKeyTap),
          const SizedBox(height: 16),
          _PinRow(['7', '8', '9'], onKeyTap: _onKeyTap),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Back to previous phase button
              GestureDetector(
                onTap: _phase == 1
                    ? () => setState(() {
                          _phase = 0;
                          _newMpin = '';
                          _confirmMpin = '';
                        })
                    : null,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_phase == 1 ? 0.04 : 0),
                    shape: BoxShape.circle,
                  ),
                  child: _phase == 1
                      ? const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textMuted, size: 24)
                      : null,
                ),
              ),
              _PinKey('0', onTap: () => _onKeyTap('0')),
              _BackspaceKey(onTap: _onBackspace),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared keypad widgets (mirrored from login_screen) ────────────────────────

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
          child: Text(digit,
              style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
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
          color: Colors.white.withOpacity(0.04),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.backspace_outlined,
              color: AppTheme.textSecondary, size: 24),
        ),
      ),
    );
  }
}
