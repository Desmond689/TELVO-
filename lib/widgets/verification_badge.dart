import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;
  final bool showLabel;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.size = 16,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified,
          color: const Color(0xFF00C853),
          size: size,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: size * 0.75,
              color: const Color(0xFF00C853),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
