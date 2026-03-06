import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_empty_state_widget.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchPaymentHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final list = provider.paymentHistory;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('PAYMENT HISTORY',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: provider.isLoading && list.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : list.isEmpty
              ? CustomEmptyStateWidget(
                  icon: Icons.history_rounded,
                  title: 'No History Yet',
                  message: 'When you approve or reject payments, they will appear here.',
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchPaymentHistory(),
                  color: AppTheme.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _HistoryCard(payment: list[i]),
                  ),
                ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final PaymentRequest payment;
  const _HistoryCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isApproved = payment.status == 'Approved';
    final dateStr = payment.verifiedAt != null 
        ? DateFormat('dd MMM, hh:mm a').format(payment.verifiedAt!)
        : 'Unknown Date';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isApproved ? AppTheme.green : AppTheme.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isApproved ? AppTheme.green : AppTheme.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.memberName,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text('UTR: **** ${payment.transactionId}',
                    style: GoogleFonts.inter(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${payment.amount.toInt()}',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
              Text(dateStr,
                  style: GoogleFonts.inter(
                      color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
