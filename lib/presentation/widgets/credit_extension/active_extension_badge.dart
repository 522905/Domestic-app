import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActiveExtensionBadge extends StatelessWidget {
  final int extensionAvailable;
  final DateTime? validUntil;
  final bool isExpiringSoon;

  const ActiveExtensionBadge({
    Key? key,
    required this.extensionAvailable,
    this.validUntil,
    this.isExpiringSoon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badgeColor = isExpiringSoon ? Colors.orange : Colors.green;

    return GestureDetector(
      onLongPress: () {
        if (validUntil != null) {
          _showExpiryTooltip(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badgeColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 14,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Credit: +$extensionAvailable',
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (isExpiringSoon) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: badgeColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showExpiryTooltip(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final expiryText = 'Expires: ${dateFormat.format(validUntil!)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(expiryText),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
