import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/dialog_utils.dart';
import '../../widgets/custom_empty_state_widget.dart';

class PaymentApprovalsScreen extends StatefulWidget {
  const PaymentApprovalsScreen({super.key});

  @override
  State<PaymentApprovalsScreen> createState() => _PaymentApprovalsScreenState();
}

class _PaymentApprovalsScreenState extends State<PaymentApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchPendingPayments();
    });
  }

  Future<void> _handleVerify(PaymentRequest payment, String status) async {
    final title = status == 'Approved' ? 'Approve Payment?' : 'Reject Payment?';
    final msg = status == 'Approved' 
        ? 'Confirm that you received ₹${payment.amount.toInt()} from ${payment.memberName} in your bank account.'
        : 'Are you sure you want to reject this request?';

    final confirmed = await DialogUtils.showConfirmation(
      context: context,
      title: title,
      message: msg,
      confirmText: status,
      isDestructive: status == 'Rejected',
    );

    if (confirmed == true) {
      final p = context.read<PaymentProvider>();
      final ok = await p.verifyPayment(payment.id, status);
      if (ok && mounted) {
        SnackbarUtils.showSuccess(context, 'Payment $status successfully!');
      } else if (mounted) {
        SnackbarUtils.showError(context, p.error ?? 'Verification failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final list = provider.pendingPayments;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('PENDING PAYMENTS', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: provider.isLoading && list.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : list.isEmpty
              ? CustomEmptyStateWidget(
                  icon: Icons.payments_rounded,
                  title: 'All Caught Up!',
                  message: 'No pending payments to verify. Your wallet is happy!',
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchPendingPayments(),
                  color: AppTheme.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _PaymentCard(
                      payment: list[i],
                      onApprove: () => _handleVerify(list[i], 'Approved'),
                      onReject: () => _handleVerify(list[i], 'Rejected'),
                    ),
                  ),
                ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentRequest payment;
  final VoidCallback onApprove, onReject;

  const _PaymentCard({
    required this.payment,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(Icons.person_rounded, color: AppTheme.accent)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.memberName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(payment.planName, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${payment.amount.toInt()}', style: GoogleFonts.inter(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 18)),
                  Text(payment.paymentApp, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Transaction ID (UTR)', payment.transactionId),
          _infoRow('Submitted', payment.createdAt.toString().split('.')[0]),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(foregroundColor: AppTheme.red),
                  child: const Text('REJECT'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green.withOpacity(0.2),
                    foregroundColor: AppTheme.green,
                    elevation: 0,
                  ),
                  child: const Text('APPROVE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String val) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11)),
        Text(val, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
