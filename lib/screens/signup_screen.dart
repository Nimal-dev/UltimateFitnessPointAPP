import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _mpinCtrl = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _mpinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim().replaceAll(RegExp(r'\D'), ''),
      mpin: _mpinCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: Text('Registration Received!', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white)),
            content: Text(
              'Your application is now under review. Please wait for the gym owner to approve your account before logging in.',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to Login
                },
                child: Text('GOT IT', style: GoogleFonts.inter(color: AppTheme.accent, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      } else {
        SnackbarUtils.showError(context, auth.error ?? 'Registration failed. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text('Join the Elite', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Fill in your details to get started on your journey.', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted)),
              
              const SizedBox(height: 40),
              
              _label('FULL NAME'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: _inputDecoration('e.g. John Doe', Icons.person_outline_rounded),
                validator: (val) => (val == null || val.isEmpty) ? 'Please enter your name' : null,
              ),
              
              const SizedBox(height: 24),
              
              _label('EMAIL ADDRESS'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: _inputDecoration('john@example.com', Icons.email_outlined),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter your email';
                  if (!val.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              _label('MOBILE NUMBER'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: _inputDecoration('9876543210', Icons.phone_android_rounded),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter your mobile number';
                  final clean = val.replaceAll(RegExp(r'\D'), '');
                  if (clean.length < 10) return 'Enter a valid 10-digit number';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              _label('SET 4-DIGIT MPIN'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mpinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                style: GoogleFonts.inter(color: Colors.white, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('••••', Icons.lock_outline_rounded).copyWith(counterText: ''),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Set an MPIN';
                  if (val.length != 4) return 'Must be 4 digits';
                  if (val == '0000') return 'Try something harder than 0000!';
                  return null;
                },
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.charcoal))
                    : Text('SUBMIT APPLICATION', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.inter(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
  );
}
