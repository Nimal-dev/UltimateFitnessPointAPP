import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../services/upi_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';

class MembershipRenewalScreen extends StatefulWidget {
  const MembershipRenewalScreen({super.key});

  @override
  State<MembershipRenewalScreen> createState() => _MembershipRenewalScreenState();
}

class _MembershipRenewalScreenState extends State<MembershipRenewalScreen> {
  final _utrCtrl = TextEditingController();
  String _selectedApp = 'GPay';
  bool _submitted = false;

  final List<Map<String, dynamic>> _plans = [
    {'name': '1 Month Basic', 'price': 500.0, 'desc': 'Standard gym access'},
    {'name': '3 Months Pro', 'price': 1350.0, 'desc': 'Save 10% + Diet Plan'},
    {'name': '6 Months Elite', 'price': 2500.0, 'desc': 'Save 20% + Trainer Assist'},
  ];
  late Map<String, dynamic> _selectedPlan;

  @override
  void initState() {
    super.initState();
    _selectedPlan = _plans[0];
  }

  @override
  void dispose() {
    _utrCtrl.dispose();
    super.dispose();
  }

  Future<void> _payNow() async {
    try {
      await UpiService.initiateUPIPayment(
        amount: _selectedPlan['price'],
        transactionNote: 'Gym Renewal: ${context.read<AuthProvider>().user?.name}',
      );
      SnackbarUtils.showInfo(context, 'Launched UPI app. Please complete payment and copy the Transaction ID (UTR).');
    } catch (e) {
      SnackbarUtils.showError(context, e.toString());
    }
  }

  Future<void> _submitRequest() async {
    final utr = _utrCtrl.text.trim();
    if (utr.length != 4) {
      SnackbarUtils.showError(context, 'Please enter the last 4 digits of the Transaction ID');
      return;
    }

    final p = context.read<PaymentProvider>();
    final ok = await p.submitPaymentRequest(
      amount: _selectedPlan['price'],
      transactionId: utr,
      paymentApp: _selectedApp,
      planName: _selectedPlan['name'],
    );

    if (ok) {
      setState(() => _submitted = true);
      SnackbarUtils.showSuccess(context, 'Payment proof submitted! Verification in progress.');
    } else {
      SnackbarUtils.showError(context, p.error ?? 'Submission failed. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessState();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('RENEW MEMBERSHIP', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader(1, 'SELECT PLAN'),
            const SizedBox(height: 12),
            ..._plans.map((p) => _planCard(p)).toList(),
            
            const SizedBox(height: 32),
            _stepHeader(2, 'PAY VIA UPI'),
            const SizedBox(height: 12),
            _paymentSection(),

            const SizedBox(height: 32),
            _stepHeader(3, 'SUBMIT PROOF'),
            const SizedBox(height: 12),
            _utrSection(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: context.watch<PaymentProvider>().isLoading ? null : _submitRequest,
                child: context.watch<PaymentProvider>().isLoading
                    ? const CircularProgressIndicator(color: AppTheme.charcoal)
                    : Text('SUBMIT FOR VERIFICATION', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _stepHeader(int num, String title) => Row(
    children: [
      Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
        child: Center(child: Text('$num', style: GoogleFonts.inter(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12))),
      ),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
    ],
  );

  Widget _planCard(Map<String, dynamic> plan) {
    final isSelected = _selectedPlan == plan;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withOpacity(0.05) : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan['name'], style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(plan['desc'], style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text('₹${plan['price'].toInt()}', style: GoogleFonts.inter(color: isSelected ? AppTheme.accent : Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _paymentSection() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
    child: Column(
      children: [
        Text(
          'Pay ₹${_selectedPlan['price'].toInt()} using your preferred app:',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _payAppBtn('GPay', Icons.payment_rounded),
            _payAppBtn('PhonePe', Icons.account_balance_wallet_rounded),
            _payAppBtn('Paytm', Icons.qr_code_scanner_rounded),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _payNow,
            icon: const Icon(Icons.launch_rounded, size: 18),
            label: Text('OPEN UPI APP', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    ),
  );

  Widget _payAppBtn(String name, IconData icon) {
    final isSel = _selectedApp == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedApp = name),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSel ? AppTheme.accent.withOpacity(0.12) : Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: isSel ? AppTheme.accent : AppTheme.border),
            ),
            child: Icon(icon, color: isSel ? AppTheme.accent : AppTheme.textMuted, size: 24),
          ),
          const SizedBox(height: 6),
          Text(name, style: GoogleFonts.inter(color: isSel ? AppTheme.accent : AppTheme.textMuted, fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _utrSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('After payment, just enter the LAST 4 DIGITS of your Transaction ID / UTR:', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
      const SizedBox(height: 14),
      TextField(
        controller: _utrCtrl,
        keyboardType: TextInputType.number,
        maxLength: 4,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Enter last 4 digits',
          prefixIcon: Icon(Icons.assignment_rounded, size: 20, color: AppTheme.textMuted),
          counterStyle: TextStyle(color: AppTheme.textMuted),
        ),
      ),
    ],
  );

  Widget _buildSuccessState() => Scaffold(
    backgroundColor: AppTheme.background,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 80),
            const SizedBox(height: 24),
            Text('SUBMITTED!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)),
            const SizedBox(height: 12),
            Text(
              'Your payment is being verified. Your membership will be renewed automatically within 24 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  UpiService.notifyOwnerViaWhatsApp(
                    ownerMobile: "918590424344", // Placeholder
                    message: "Hi Coach, I've just submitted my membership renewal payment of ₹${_selectedPlan['price'].toInt()} (Transaction ID: ${_utrCtrl.text}). Please verify it!",
                  );
                },
                icon: const Icon(Icons.chat_bubble_rounded),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'NOTIFY OWNER ON WHATSAPP',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('BACK TO DASHBOARD', style: GoogleFonts.inter(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ),
  );
}
