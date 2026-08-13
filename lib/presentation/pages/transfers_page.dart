import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/di/injection.dart';
import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'transfer_form_page.dart';

class TransfersPage extends StatelessWidget {
  const TransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransfersBloc>()..add(const TransfersRequested()),
      child: const TransfersView(),
    );
  }
}

/// La vista sin el BlocProvider, para poder inyectar un bloc propio en tests.
class TransfersView extends StatelessWidget {
  const TransfersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferencias')),
      floatingActionButton: BlocBuilder<TransfersBloc, TransfersState>(
        builder: (context, state) {
          if (state is! TransfersReady) return const SizedBox.shrink();

          final bloc = context.read<TransfersBloc>();
          final enoughUsers = state.users.length >= 2;

          return FloatingActionButton.extended(
            backgroundColor: enoughUsers ? turquoise : mistEdge,
            foregroundColor: enoughUsers ? Colors.white : teal,
            icon: const Icon(Icons.add),
            label: const Text('Nueva transferencia'),
            onPressed: enoughUsers
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: TransferFormPage(users: state.users),
                        ),
                      ),
                    )
                : () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Necesitas al menos dos usuarios para transferir'),
                    ),
                  ),
          );
        },
      ),
      body: BlocBuilder<TransfersBloc, TransfersState>(
        builder: (context, state) => switch (state) {
          TransfersLoading() => const Center(child: CircularProgressIndicator(color: turquoise)),
          TransfersLoadFailed(:final message) => _LoadFailed(message: message),
          TransfersReady(:final transfers) when transfers.isEmpty => const _Empty(),
          TransfersReady() => _History(state: state),
        },
      ),
    );
  }
}

class _History extends StatelessWidget {
  final TransfersReady state;

  const _History({required this.state});

  @override
  Widget build(BuildContext context) {
    final transfers = state.transfers;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          itemCount: transfers.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '${transfers.length} ${transfers.length == 1 ? 'MOVIMIENTO' : 'MOVIMIENTOS'}',
                  style: eyebrow.copyWith(color: turquoise),
                ),
              );
            }

            final transfer = transfers[index - 1];
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${state.nameOf(transfer.sourceUserId)}  â†’  ${state.nameOf(transfer.destinationUserId)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: deepAqua,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatMoney(transfer.amountInCents),
                          style: tabular.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: turquoise,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDateTime(transfer.createdAt),
                      style: tabular.copyWith(fontSize: 12, color: teal.withValues(alpha: 0.7)),
                    ),
                    if (transfer.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        transfer.description!,
                        style: TextStyle(fontSize: 13, color: teal.withValues(alpha: 0.9)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SIN MOVIMIENTOS', style: eyebrow.copyWith(color: turquoise)),
            const SizedBox(height: 10),
            Text(
              'Registra la primera transferencia para ver su comprobante aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: teal.withValues(alpha: 0.9), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  final String message;

  const _LoadFailed({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: danger)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<TransfersBloc>().add(const TransfersRequested()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
