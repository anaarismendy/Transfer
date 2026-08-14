import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/validation.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';
import 'package:prueba_tecnica/presentation/widgets/soft.dart';

class UserFormPage extends StatefulWidget {
  final User? user;

  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  bool _confirmingDelete = false;
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.user == null;

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

  bool get _filled =>
      _name.text.trim().isNotEmpty && _email.text.trim().isNotEmpty;

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    context.read<UsersBloc>().add(
      UserSubmitted(
        id: widget.user?.id,
        name: _name.text,
        email: _email.text,
        password: _password.text.isEmpty ? null : _password.text,
      ),
    );
  }

  void _onUsersState(BuildContext context, UsersState state) {
    final ready = state as UsersReady;

    if (ready.noticeIsError) {
      setState(() {
        _saving = false;
        _error = ready.notice;
      });
      return;
    }

    Navigator.of(context).pop();
  }

  void _delete() {
    context.read<UsersBloc>().add(UserRemoved(widget.user!.id));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: BlocListener<UsersBloc, UsersState>(
            listenWhen: (_, current) =>
                _saving && current is UsersReady && current.notice != null,
            listener: _onUsersState,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  Row(
                    children: [
                      const BackCircle(),
                      const SizedBox(width: 14),
                      Text(
                        _isNew ? 'Nuevo contacto' : 'Editar contacto',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Center(
                    child: Avatar(
                      name: _name.text.isEmpty ? '?' : _name.text,
                      seed: widget.user?.id ?? _email.text,
                      size: 84,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SoftField(
                    label: 'Nombre completo',
                    hint: 'Ej. Julian Gomez',
                    controller: _name,
                    onChanged: (_) => setState(() {}),
                    validator: (value) => validateName(value ?? '')?.message,
                  ),
                  const SizedBox(height: 14),
                  SoftField(
                    label: 'Correo',
                    hint: 'ejemplo@correo.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    validator: (value) => validateEmail(value ?? '')?.message,
                  ),
                  const SizedBox(height: 14),
                  SoftField(
                    label: _isNew
                        ? 'Contrasena'
                        : 'Nueva contrasena (opcional)',
                    hint: 'Minimo $passwordMinLength caracteres',
                    controller: _password,
                    obscure: true,
                    validator: (value) {
                      final text = value ?? '';
                      if (!_isNew && text.isEmpty) return null;
                      return validatePassword(text)?.message;
                    },
                  ),
                  const SizedBox(height: 26),
                  if (_error != null) ...[
                    _errorCard(_error!),
                    const SizedBox(height: 16),
                  ],
                  GradientButton(
                    label: 'Guardar contacto',
                    onPressed: _filled && !_saving ? _save : null,
                  ),
                  if (!_isNew) ...[
                    const SizedBox(height: 16),
                    if (_confirmingDelete) _deleteConfirm() else _deleteLink(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorCard(String message) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: rose.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: sentInk, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: sentInk,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _deleteLink() => GestureDetector(
    onTap: () => setState(() => _confirmingDelete = true),
    child: const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          'Eliminar contacto',
          style: TextStyle(
            color: rose,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    ),
  );

  Widget _deleteConfirm() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: rose.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            '¿Eliminar este contacto?',
            style: TextStyle(fontSize: 13, color: ink),
          ),
        ),
        GestureDetector(
          onTap: _delete,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: rose,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Si',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _confirmingDelete = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: violet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'No',
              style: TextStyle(
                color: inkSoft,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
