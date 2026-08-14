import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/usecases/seed_default_user.dart';
import 'package:prueba_tecnica/domain/validation.dart';
import 'package:prueba_tecnica/presentation/blocs/auth_bloc.dart';
import 'package:prueba_tecnica/presentation/widgets/soft.dart';
import 'package:prueba_tecnica/presentation/widgets/wordmark.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _filled =>
      _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginRequested(_email.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 40, 26, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 72,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: _form(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final busy = state is AuthInProgress;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: Wordmark()),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Transfer',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Center(
                child: Text(
                  'Transfiere dinero de forma simple\ny segura',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: mutedWarm,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SoftField(
                hint: 'Correo',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                validator: (value) => validateEmail(value ?? '')?.message,
              ),
              const SizedBox(height: 13),
              SoftField(
                hint: 'Contrasena',
                controller: _password,
                obscure: _obscure,
                onChanged: (_) => setState(() {}),
                validator: (value) =>
                    (value ?? '').isEmpty ? 'Escribe tu contrasena' : null,
                trailing: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: placeholderInk,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _notice(
                    context,
                    'Pidele al administrador que la restablezca',
                  ),
                  child: const Text(
                    '¿Olvidaste tu contrasena?',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: violet,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (state is AuthFailed) ...[
                _error(state.message),
                const SizedBox(height: 16),
              ],
              if (busy)
                const Center(child: CircularProgressIndicator(color: violet))
              else
                GradientButton(
                  label: 'Iniciar sesion',
                  onPressed: _filled ? _submit : null,
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: hairline, height: 1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'o',
                      style: TextStyle(fontSize: 11.5, color: muted),
                    ),
                  ),
                  const Expanded(child: Divider(color: hairline, height: 1)),
                ],
              ),
              const SizedBox(height: 20),
              SoftButton(
                label: 'Crear cuenta nueva',
                onPressed: () =>
                    _notice(context, 'Las cuentas se crean desde Contactos'),
              ),
              const SizedBox(height: 28),
              _demoCredentials(),
            ],
          ),
        );
      },
    );
  }

  Widget _error(String message) => Container(
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

  Widget _demoCredentials() => Column(
    children: [
      const Text(
        'ACCESO DE PRUEBA',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          color: muted,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${SeedDefaultUser.email}   ·   ${SeedDefaultUser.password}',
        style: const TextStyle(
          fontSize: 12.5,
          color: inkSoft,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  void _notice(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
