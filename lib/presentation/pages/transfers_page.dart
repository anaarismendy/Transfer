import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/di/injection.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/transfer_form_page.dart';
import 'package:prueba_tecnica/presentation/widgets/movement_row.dart';
import 'package:prueba_tecnica/presentation/widgets/soft.dart';

enum MovementFilter { all, sent, received }

class TransfersPage extends StatelessWidget {
  final User user;

  const TransfersPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransfersBloc>()..add(const TransfersRequested()),
      child: Builder(
        builder: (context) => Scaffold(
          body: ScreenBackground(child: TransfersView(currentUser: user)),
          floatingActionButton: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: brandGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<TransfersBloc>(),
                    child: TransferFormPage(me: user),
                  ),
                ),
              ),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TransfersView extends StatefulWidget {
  final User currentUser;

  const TransfersView({super.key, required this.currentUser});

  @override
  State<TransfersView> createState() => _TransfersViewState();
}

class _TransfersViewState extends State<TransfersView> {
  MovementFilter _filter = MovementFilter.all;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransfersBloc, TransfersState>(
      listenWhen: (_, current) =>
          current is TransfersReady && current.error != null,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((state as TransfersReady).error!),
          backgroundColor: sentInk,
        ),
      ),
      builder: (context, state) => SafeArea(
        bottom: false,
        child: switch (state) {
          TransfersLoading() => const Center(
            child: CircularProgressIndicator(color: violet),
          ),
          TransfersLoadFailed(:final message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: sentInk, fontSize: 14),
              ),
            ),
          ),
          TransfersReady() => _history(state),
        },
      ),
    );
  }

  Widget _history(TransfersReady ready) {
    final me = widget.currentUser.id;
    final visible = ready.transfers
        .where(
          (t) => switch (_filter) {
            MovementFilter.all => true,
            MovementFilter.sent => t.sourceUserId == me,
            MovementFilter.received => t.destinationUserId == me,
          },
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, tabBarGap),
      children: [
        const PageHeading(text: 'Historial'),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('Todos', MovementFilter.all),
              const SizedBox(width: 10),
              _chip('Enviados', MovementFilter.sent),
              const SizedBox(width: 10),
              _chip('Recibidos', MovementFilter.received),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (visible.isEmpty)
          const SoftCard(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'No hay movimientos',
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ),
            ),
          )
        else
          SoftList(
            children: [for (final transfer in visible) _row(ready, transfer)],
          ),
      ],
    );
  }

  Widget _row(TransfersReady ready, Transfer transfer) {
    final me = widget.currentUser.id;
    final counterpartId = transfer.sourceUserId == me
        ? transfer.destinationUserId
        : transfer.sourceUserId;

    return MovementRow(
      transfer: transfer,
      currentUserId: me,
      counterpartName: ready.nameOf(counterpartId),
    );
  }

  Widget _chip(String label, MovementFilter value) {
    final active = _filter == value;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? brandGradient : null,
          color: active ? null : surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF8278C3).withValues(alpha: 0.35),
                    offset: const Offset(4, 4),
                    blurRadius: 10,
                  ),
                ]
              : softShadows(spread: 0.7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : inkSoft,
          ),
        ),
      ),
    );
  }
}
