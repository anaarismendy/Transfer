import 'package:flutter/material.dart';

import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';

class ReceiptPage extends StatelessWidget {
  final Transfer transfer;
  final User source;
  final User destination;

  const ReceiptPage({
    super.key,
    required this.transfer,
    required this.source,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepAqua,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'COMPROBANTE',
                                    style: eyebrow.copyWith(color: turquoise),
                                  ),
                                  const Icon(Icons.check_circle, color: turquoise, size: 20),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                formatMoney(transfer.amountInCents),
                                style: tabular.copyWith(
                                  fontSize: 34,
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                  color: deepAqua,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Transferencia registrada',
                                style: TextStyle(fontSize: 13, color: teal.withValues(alpha: 0.8)),
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1, color: mistEdge),
                              const SizedBox(height: 16),
                              _Row(label: 'ORIGEN', value: source.name, detail: source.email),
                              const SizedBox(height: 14),
                              _Row(
                                label: 'DESTINO',
                                value: destination.name,
                                detail: destination.email,
                              ),
                              const SizedBox(height: 14),
                              _Row(
                                label: 'FECHA',
                                value: formatDateTime(transfer.createdAt),
                                monospaceValue: true,
                              ),
                              if (transfer.description != null) ...[
                                const SizedBox(height: 14),
                                _Row(label: 'DESCRIPCION', value: transfer.description!),
                              ],
                              const SizedBox(height: 14),
                              _Row(
                                label: 'COMPROBANTE No.',
                                value: transfer.id.substring(0, 8).toUpperCase(),
                                monospaceValue: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Listo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final bool monospaceValue;

  const _Row({
    required this.label,
    required this.value,
    this.detail,
    this.monospaceValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: eyebrow.copyWith(color: teal.withValues(alpha: 0.55), fontSize: 10)),
        const SizedBox(height: 3),
        Text(
          value,
          style: (monospaceValue ? tabular : const TextStyle()).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: deepAqua,
          ),
        ),
        if (detail != null)
          Text(detail!, style: TextStyle(fontSize: 12, color: teal.withValues(alpha: 0.7))),
      ],
    );
  }
}
