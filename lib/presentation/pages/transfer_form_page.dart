import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'receipt_page.dart';

class TransferFormPage extends StatefulWidget {
  final List<User> users;

  const TransferFormPage({super.key, required this.users});

  @override
  State<TransferFormPage> createState() => _TransferFormPageState();
}

class _TransferFormPageState extends State<TransferFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  User? _source;
  User? _destination;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    context.read<TransfersBloc>().add(
          TransferSubmitted(
            sourceUserId: _source!.id,
            destinationUserId: _destination!.id,
            amountInCents: parsePesosToCents(_amount.text)!,
            description: _description.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Excluir el origen del destino evita el error antes de que ocurra; la
    // regla sigue validada en el caso de uso y en la base.
    final destinations = widget.users.where((u) => u.id != _source?.id).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva transferencia')),
      body: BlocListener<TransfersBloc, TransfersState>(
        listenWhen: (_, current) =>
            current is TransfersReady && (current.error != null || current.created != null),
        listener: (context, state) {
          final ready = state as TransfersReady;
          setState(() => _saving = false);

          if (ready.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(ready.error!), backgroundColor: danger));
            return;
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ReceiptPage(
                transfer: ready.created!,
                source: _source!,
                destination: _destination!,
              ),
            ),
          );
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('DATOS', style: eyebrow.copyWith(color: turquoise)),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<User>(
                                initialValue: _source,
                                decoration: const InputDecoration(labelText: 'Origen'),
                                items: widget.users
                                    .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(() {
                                          _source = value;
                                          if (_destination?.id == value?.id) _destination = null;
                                        }),
                                validator: (v) => v == null ? 'Selecciona el origen' : null,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<User>(
                                initialValue: _destination,
                                decoration: const InputDecoration(labelText: 'Destino'),
                                items: destinations
                                    .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(() => _destination = value),
                                validator: (v) => v == null ? 'Selecciona el destino' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _amount,
                                enabled: !_saving,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: tabular,
                                decoration: const InputDecoration(
                                  labelText: 'Valor',
                                  prefixText: '\$ ',
                                  helperText: 'En pesos, sin puntos ni centavos',
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  final cents = parsePesosToCents(v ?? '');
                                  if (cents == null) return 'Escribe el valor';
                                  if (cents <= 0) return 'El valor debe ser mayor a cero';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _description,
                                enabled: !_saving,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Descripcion',
                                  helperText: 'Opcional',
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _saving ? null : _submit,
                                child: _saving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Registrar transferencia'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
