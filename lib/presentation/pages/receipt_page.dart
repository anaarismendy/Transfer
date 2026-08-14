import 'package:flutter/material.dart';

import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';
import 'package:prueba_tecnica/presentation/widgets/soft.dart';

class ReceiptPage extends StatelessWidget {
  final Transfer transfer;
  final String sourceName;
  final String destinationName;
  final VoidCallback? onNewTransfer;

  const ReceiptPage({
    super.key,
    required this.transfer,
    required this.sourceName,
    required this.destinationName,
    this.onNewTransfer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            children: [
              Center(child: _check()),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '¡Transferencia exitosa!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Enviaste '),
                      TextSpan(
                        text: formatMoney(transfer.amountInCents),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: '\na $destinationName'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: inkSoft,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _receipt(),
              const SizedBox(height: 28),
              GradientButton(
                label: 'Volver al inicio',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),
              if (onNewTransfer != null)
                GestureDetector(
                  onTap: onNewTransfer,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        'Nueva transferencia',
                        style: TextStyle(
                          color: violet,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _check() => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.55, end: 1),
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeOut,
    builder: (context, value, child) =>
        Transform.scale(scale: value, child: child),
    child: Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: brandGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8278C3).withValues(alpha: 0.40),
            offset: const Offset(8, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 46),
    ),
  );

  /// El comprobante que pide la prueba: lo que quedo guardado, tal cual.
  Widget _receipt() => SoftCard(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMPROBANTE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.4,
            color: muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _line('Origen', sourceName),
        _line('Destino', destinationName),
        _line('Valor', formatMoney(transfer.amountInCents)),
        if (transfer.description != null) _line('Nota', transfer.description!),
        _line('Fecha', formatDateTime(transfer.createdAt)),
        _line('Referencia', transfer.id.split('-').first),
      ],
    ),
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13.5,
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
