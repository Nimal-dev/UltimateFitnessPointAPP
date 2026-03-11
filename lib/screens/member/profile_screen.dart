import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/dialog_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String? _selectedGender;
  String? _selectedActivityLevel;

  final _currentMpinCtrl = TextEditingController();
  final _newMpinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _weightCtrl.text = user.weight?.toString() ?? '';
      _heightCtrl.text = user.height?.toString() ?? '';
      _ageCtrl.text = user.age?.toString() ?? '';
      _selectedGender = user.gender;
      _selectedActivityLevel = user.activityLevel ?? 'Sedentary';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _currentMpinCtrl.dispose();
    _newMpinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    final name = _nameCtrl.text.trim();
    final weight = double.tryParse(_weightCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());
    final age = int.tryParse(_ageCtrl.text.trim());

    if (name.isEmpty) {
      SnackbarUtils.showError(context, 'Name cannot be empty, champ!');
      return;
    }

    final ok = await context.read<AuthProvider>().updateProfile({
      'name': name,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (age != null) 'age': age,
      if (_selectedGender != null) 'gender': _selectedGender,
      if (_selectedActivityLevel != null) 'activityLevel': _selectedActivityLevel,
    });

    if (ok && mounted) {
      SnackbarUtils.showSuccess(context, 'Profile updated! Looking sharper already.');
    } else if (mounted) {
      SnackbarUtils.showError(context, context.read<AuthProvider>().error ?? 'Update failed');
    }
  }

  Future<void> _showChangeMpinDialog() async {
    _currentMpinCtrl.clear();
    _newMpinCtrl.clear();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('CHANGE MPIN', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_currentMpinCtrl, 'Current 4-digit MPIN', Icons.lock_outline_rounded, isMpin: true),
            const SizedBox(height: 16),
            _field(_newMpinCtrl, 'New 4-digit MPIN', Icons.fiber_new_rounded, isMpin: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () async {
              if (_newMpinCtrl.text.length != 4 || _currentMpinCtrl.text.length != 4) {
                SnackbarUtils.showError(context, 'MPIN must be 4 digits.');
                return;
              }
              final ok = await context.read<AuthProvider>().changeMpin(_currentMpinCtrl.text, _newMpinCtrl.text);
              if (ok && mounted) {
                Navigator.pop(ctx);
                SnackbarUtils.showSuccess(context, 'MPIN changed successfully!');
              } else if (mounted) {
                SnackbarUtils.showError(context, context.read<AuthProvider>().error ?? 'Change failed.');
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('MY PROFILE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and Stats Summary
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accent, width: 2),
                    ),
                    child: Center(
                      child: Text(user.initials, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.accent)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(user.mobile ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _sectionTitle('PERSONAL INFO'),
            _field(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
            const SizedBox(height: 24),

            _sectionTitle('BODY METRICS'),
            Row(
              children: [
                Expanded(child: _field(_weightCtrl, 'Weight (kg)', Icons.monitor_weight_outlined, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _field(_heightCtrl, 'Height (cm)', Icons.height_rounded, isNumber: true)),
              ],
            ),
            const SizedBox(height: 16),
            _field(_ageCtrl, 'Age', Icons.calendar_today_rounded, isNumber: true),
            const SizedBox(height: 16),
            _dropdown('Gender', _selectedGender, ['Male', 'Female', 'Other'], (val) => setState(() => _selectedGender = val)),
            const SizedBox(height: 16),
            _dropdown('Activity Level', _selectedActivityLevel, ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active'], (val) => setState(() => _selectedActivityLevel = val)),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _handleUpdateProfile,
                child: auth.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('SAVE CHANGES', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 24),

            _sectionTitle('SECURITY'),
            _actionTile(
              'Change MPIN', 
              'Update your 4-digit access code', 
              Icons.lock_reset_rounded, 
              _showChangeMpinDialog
            ),
            const SizedBox(height: 12),
            _actionTile(
              'Logout', 
              'Sign out of your account', 
              Icons.logout_rounded, 
              () async {
                final ok = await DialogUtils.showConfirmation(
                  context: context, 
                  title: 'LOGOUT', 
                  message: 'Are you sure you want to end your session?',
                  confirmText: 'LOGOUT',
                  isDestructive: true
                );
                if (ok == true && mounted) {
                  context.read<AuthProvider>().logout();
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.accent, letterSpacing: 1.5)),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false, bool isMpin = false}) => TextField(
    controller: ctrl,
    keyboardType: isNumber || isMpin ? TextInputType.number : TextInputType.text,
    maxLength: isMpin ? 4 : null,
    obscureText: isMpin,
    onChanged: isMpin ? (_) => HapticFeedback.vibrate() : null,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
      counterText: '',
    ),
  );

  Widget _actionTile(String title, String sub, IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(sub, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    ),
  );

  Widget _dropdown(String hint, String? value, List<String> items, Function(String?) onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        dropdownColor: AppTheme.cardBackground,
        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
        isExpanded: true,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 14)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
