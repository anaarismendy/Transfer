import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/presentation/blocs/auth_bloc.dart';
import 'package:prueba_tecnica/presentation/widgets/wordmark.dart';
import 'transfers_page.dart';
import 'users_page.dart';

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Wordmark(showTagline: false, fontSize: 15),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
            onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SESION ACTIVA', style: eyebrow.copyWith(color: turquoise)),
                  const SizedBox(height: 8),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: deepAqua,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(user.email, style: TextStyle(fontSize: 14, color: teal.withValues(alpha: 0.85))),
                  const SizedBox(height: 26),
                  _ModuleTile(
                    icon: Icons.people_outline,
                    title: 'Usuarios',
                    subtitle: 'Crear, editar y eliminar usuarios',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UsersPage()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ModuleTile(
                    icon: Icons.swap_horiz,
                    title: 'Transferencias',
                    subtitle: 'Registrar una transferencia y ver su comprobante',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TransfersPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: enabled ? turquoise : mistEdge, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled ? deepAqua : teal.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      enabled ? subtitle : 'Proximamente',
                      style: TextStyle(fontSize: 13, color: teal.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
              if (enabled) const Icon(Icons.chevron_right, color: mistEdge),
            ],
          ),
        ),
      ),
    );
  }
}
