import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/payment_config.dart';

class CommissionDisclaimer extends StatelessWidget {
  final bool forClient;
  final double? budget;
  final String currency;

  const CommissionDisclaimer({
    super.key,
    required this.forClient,
    this.budget,
    this.currency = 'USD',
  });

  @override
  Widget build(BuildContext context) {
    final rate = kPlatformCommissionRate;
    final ratePct = (rate * 100).toStringAsFixed(0);
    final hasBudget = budget != null && budget! > 0;
    final freelancerShare = hasBudget ? budget! * (1 - rate) : null;
    final commissionShare = hasBudget ? budget! * rate : null;

    final String message;
    if (forClient) {
      message = hasBudget
          ? 'This budget ($currency ${budget!.toStringAsFixed(0)}) is paid in full to the freelancer '
              'and the platform, split at completion: $currency ${freelancerShare!.toStringAsFixed(0)} to '
              'the freelancer and $currency ${commissionShare!.toStringAsFixed(0)} ($ratePct%) as a '
              'platform fee. You won\'t be charged anything extra beyond this amount.'
          : 'A $ratePct% platform fee is included in this budget. It\'s paid directly to WorkByte '
              'alongside the freelancer\'s share when the project completes. You won\'t be charged '
              'anything on top of the budget you set.';
    } else {
      message = hasBudget
          ? 'A $ratePct% platform fee applies to this budget. If this proposal is accepted at '
              '$currency ${budget!.toStringAsFixed(0)}, you\'ll receive $currency '
              '${freelancerShare!.toStringAsFixed(0)}. The client pays the remaining $currency '
              '${commissionShare!.toStringAsFixed(0)} directly to WorkByte as a platform fee.'
          : 'A $ratePct% platform fee applies to whatever budget is agreed. You\'ll receive $ratePct% '
              'less than the client\'s payment as WorkByte\'s service fee.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: const Color(0xFF3730A3),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
