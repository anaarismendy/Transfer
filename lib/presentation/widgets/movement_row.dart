import 'package:flutter/material.dart';

import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';

class MovementRow extends StatelessWidget {
  final Transfer transfer;
  final String currentUserId;
  final String counterpartName;

  const MovementRow({
    super.key,
    required this.transfer,
    required this.currentUserId,
    required this.counterpartName,
  });

  bool get isSent => transfer.sourceUserId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final color = isSent ? violet : skyBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSent ? Icons.north_east_rounded : Icons.south_west_rounded,
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counterpartName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                Text(
                  formatRelative(transfer.createdAt),
                  style: const TextStyle(fontSize: 11.5, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isSent ? '-' : '+'}${formatMoney(transfer.amountInCents)}',
            style: tabular.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSent ? sentInk : receivedInk,
            ),
          ),
        ],
      ),
    );
  }
}
