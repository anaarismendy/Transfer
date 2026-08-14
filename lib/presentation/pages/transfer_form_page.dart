import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/di/injection.dart';
import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/receipt_page.dart';
import 'package:prueba_tecnica/presentation/pages/user_form_page.dart';
import 'package:prueba_tecnica/presentation/widgets/soft.dart';

enum TransferStep { select, amount, confirm }

const _keypad = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'back'];

class TransferFormPage extends StatefulWidget {
  final User me;
  final User? contact;

  const TransferFormPage({super.key, required this.me, this.contact});

  @override
  State<TransferFormPage> createState() => _TransferFormPageState();
}

class _TransferFormPageState extends State<TransferFormPage> {
  final _note = TextEditingController();
  late User _source;
  User? _contact;
  TransferStep _step = TransferStep.select;
  String _amount = '';
  String _search = '';
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _source = widget.me;
    _contact = widget.contact;
    if (_contact != null) _step = TransferStep.amount;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int? get _cents => parseKeypadToCents(_amount);

  void _back() {
    switch (_step) {
      case TransferStep.select:
        Navigator.of(context).pop();
      case TransferStep.amount:
        setState(() => _step = TransferStep.select);
      case TransferStep.confirm:
        setState(() => _step = TransferStep.amount);
    }
  }

  void _press(String key) {
    setState(() {
      if (key == 'back') {
        _amount = _amount.isEmpty
            ? ''
            : _amount.substring(0, _amount.length - 1);
        return;
      }
      if (key == '.') {
        if (!_amount.contains('.') && _amount.isNotEmpty) _amount += '.';
        return;
      }
      final decimals = _amount.split('.');
      if (decimals.length > 1 && decimals[1].length >= 2) return;
      if (_amount.length >= 10) return;
      _amount = _amount == '0' ? key : _amount + key;
    });
  }

  void _submit() {
    final cents = _cents;
    if (cents == null || _contact == null) return;

    setState(() => _submitted = true);
    context.read<TransfersBloc>().add(
      TransferSubmitted(
        sourceUserId: _source.id,
        destinationUserId: _contact!.id,
        amountInCents: cents,
        description: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: BlocConsumer<TransfersBloc, TransfersState>(
            listener: _onState,
            builder: (context, state) {
              final ready = state is TransfersReady ? state : null;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  Row(
                    children: [
                      SoftCircleButton(
                        size: 42,
                        onPressed: _back,
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: inkSoft,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Transferir',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (ready == null)
                    const Center(
                      child: CircularProgressIndicator(color: violet),
                    )
                  else
                    switch (_step) {
                      TransferStep.select => _selectStep(ready),
                      TransferStep.amount => _amountStep(),
                      TransferStep.confirm => _confirmStep(ready),
                    },
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _onState(BuildContext context, TransfersState state) {
    if (state is! TransfersReady || !_submitted) return;

    if (state.error != null) {
      setState(() => _submitted = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!), backgroundColor: sentInk),
      );
      return;
    }

    final created = state.created;
    if (created == null) return;

    final transfers = context.read<TransfersBloc>();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReceiptPage(
          transfer: created,
          sourceName: state.nameOf(created.sourceUserId),
          destinationName: state.nameOf(created.destinationUserId),
          onNewTransfer: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: transfers,
                child: TransferFormPage(me: widget.me),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectStep(TransfersReady ready) {
    final query = _search.trim().toLowerCase();
    final options = ready.users
        .where((u) => u.id != _source.id)
        .where(
          (u) =>
              query.isEmpty ||
              u.name.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sourceRow(ready),
        const SizedBox(height: 16),
        SoftField(
          hint: 'Buscar contacto',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _newContact(ready),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: violetDeep.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: violetDeep.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, size: 16, color: violet),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nuevo contacto',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: violet,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (options.isEmpty)
          const SoftCard(
            child: Padding(
              padding: EdgeInsets.all(26),
              child: Center(
                child: Text(
                  'No se encontraron contactos',
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ),
            ),
          )
        else
          SoftList(
            children: [
              for (final user in options)
                GestureDetector(
                  onTap: () => setState(() {
                    _contact = user;
                    _step = TransferStep.amount;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Avatar(name: user.name, seed: user.id),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: ink,
                                ),
                              ),
                              Text(
                                user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _sourceRow(TransfersReady ready) {
    return GestureDetector(
      onTap: () => _pickSource(ready),
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Avatar(name: _source.name, seed: _source.id, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Desde',
                    style: TextStyle(fontSize: 11.5, color: muted),
                  ),
                  Text(
                    _source.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Cambiar',
              style: TextStyle(
                fontSize: 12.5,
                color: violet,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountStep() {
    final contact = _contact!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Avatar(name: contact.name, seed: contact.id, size: 74),
            const SizedBox(height: 10),
            Text(
              contact.name,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        DecoratedBox(
          decoration: softInset(radius: 22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              children: [
                const Text(
                  'Monto a enviar',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${formatKeypadAmount(_amount)}',
                  style: tabular.copyWith(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.85,
          children: [
            for (final key in _keypad)
              GestureDetector(
                onTap: () => _press(key),
                child: Container(
                  alignment: Alignment.center,
                  decoration: softRaised(radius: 18),
                  child: key == 'back'
                      ? const Icon(
                          Icons.backspace_outlined,
                          size: 19,
                          color: ink,
                        )
                      : Text(
                          key == '.' ? ',' : key,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        GradientButton(
          label: 'Continuar',
          onPressed: _cents == null
              ? null
              : () => setState(() => _step = TransferStep.confirm),
        ),
      ],
    );
  }

  Widget _confirmStep(TransfersReady ready) {
    final contact = _contact!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vas a enviar',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 6),
              Text(
                formatMoney(_cents ?? 0),
                style: tabular.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(color: hairline, height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Avatar(name: contact.name, seed: contact.id, size: 52),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Para',
                        style: TextStyle(fontSize: 11.5, color: muted),
                      ),
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sourceRow(ready),
        const SizedBox(height: 16),
        SoftField(hint: 'Agregar una nota (opcional)', controller: _note),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Confirmar transferencia',
          onPressed: _submitted ? null : _submit,
        ),
      ],
    );
  }

  void _pickSource(TransfersReady ready) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bgTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          children: [
            const Text(
              'Usuario origen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 16),
            SoftList(
              children: [
                for (final user in ready.users)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      setState(() {
                        _source = user;
                        if (_contact?.id == user.id) {
                          _contact = null;
                          _step = TransferStep.select;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Avatar(name: user.name, seed: user.id, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                          ),
                          if (user.id == _source.id)
                            const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: violet,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _newContact(TransfersReady ready) async {
    final transfers = context.read<TransfersBloc>();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<UsersBloc>(),
          child: const UserFormPage(),
        ),
      ),
    );

    transfers.add(const TransfersRequested());
  }
}
