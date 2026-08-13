import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/validation.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';

class UserFormPage extends StatefulWidget {
  final User? user;

  const UserFormPage({super.key, this.user});

  bool get isNew => user == null;

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  bool _obscured = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user?.name ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    context.read<UsersBloc>().add(
          UserSubmitted(
            id: widget.user?.id,
            name: _name.text,
            email: _email.text,
            password: _password.text.isEmpty ? null : _password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isNew ? 'Nuevo usuario' : 'Editar usuario')),
      body: BlocListener<UsersBloc, UsersState>(
        listenWhen: (_, current) => current is UsersReady && current.notice != null,
        listener: (context, state) {
          final ready = state as UsersReady;
          setState(() => _saving = false);
          if (ready.noticeIsError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(ready.notice!),
                backgroundColor: danger,
              ));
            return;
          }
          Navigator.of(context).pop();
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
                              TextFormField(
                                controller: _name,
                                enabled: !_saving,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(labelText: 'Nombre'),
                                textInputAction: TextInputAction.next,
                                validator: (v) => validateName(v ?? '')?.message,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _email,
                                enabled: !_saving,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: 'Correo'),
                                textInputAction: TextInputAction.next,
                                validator: (v) => validateEmail(v ?? '')?.message,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                enabled: !_saving,
                                obscureText: _obscured,
                                decoration: InputDecoration(
                                  labelText: 'Contrasena',
                                  helperText: widget.isNew
                                      ? 'Minimo $passwordMinLength caracteres'
                                      : 'Dejala vacia para conservar la actual',
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscured
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    tooltip: _obscured
                                        ? 'Mostrar contrasena'
                                        : 'Ocultar contrasena',
                                    onPressed: () => setState(() => _obscured = !_obscured),
                                  ),
                                ),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) {
                                  final text = v ?? '';
                                  if (!widget.isNew && text.isEmpty) return null;
                                  return validatePassword(text)?.message;
                                },
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
                                    : Text(widget.isNew ? 'Crear usuario' : 'Guardar cambios'),
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
