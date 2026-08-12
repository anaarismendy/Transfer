import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../domain/usecases/seed_default_user.dart';
import '../blocs/auth_bloc.dart';
import '../widgets/wordmark.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          LoginRequested(_emailController.text, _passwordController.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepAqua,
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, current) => current is AuthFailed,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text((state as AuthFailed).message)));
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 22),
                          child: Wordmark(fontSize: 26),
                        ),
                        _LoginCard(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          obscured: _obscured,
                          onToggleObscured: () => setState(() => _obscured = !_obscured),
                          onSubmit: _submit,
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
    );
  }
}

class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscured;
  final VoidCallback onToggleObscured;
  final VoidCallback onSubmit;

  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscured,
    required this.onToggleObscured,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthBloc>().state is AuthInProgress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ACCESO', style: eyebrow.copyWith(color: turquoise)),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Escribe tu correo';
                  if (!text.contains('@')) return 'El correo no tiene un formato valido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                enabled: !busy,
                obscureText: obscured,
                decoration: InputDecoration(
                  labelText: 'Contrasena',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    tooltip: obscured ? 'Mostrar contrasena' : 'Ocultar contrasena',
                    onPressed: onToggleObscured,
                  ),
                ),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => onSubmit(),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Escribe tu contrasena' : null,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: busy ? null : onSubmit,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: mistEdge),
              const SizedBox(height: 14),
              const _DemoCredentials(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoCredentials extends StatelessWidget {
  const _DemoCredentials();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('USUARIO DE PRUEBA', style: eyebrow.copyWith(color: teal.withValues(alpha: 0.55))),
        const SizedBox(height: 5),
        Text(
          '${SeedDefaultUser.email}   ${SeedDefaultUser.password}',
          style: tabular.copyWith(
            color: turquoise,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
