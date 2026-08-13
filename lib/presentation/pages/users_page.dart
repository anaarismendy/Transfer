import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/di/injection.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';
import 'user_form_page.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UsersBloc>()..add(const UsersRequested()),
      child: const UsersView(),
    );
  }
}

/// La vista sin el BlocProvider, para poder inyectar un bloc propio en tests.
class UsersView extends StatelessWidget {
  const UsersView({super.key});

  Future<void> _openForm(BuildContext context, {User? user}) {
    final bloc = context.read<UsersBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: bloc, child: UserFormPage(user: user)),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, User user) async {
    final bloc = context.read<UsersBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('Se eliminara a ${user.name}. Esta accion no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) bloc.add(UserRemoved(user.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: turquoise,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo usuario'),
      ),
      body: BlocConsumer<UsersBloc, UsersState>(
        listenWhen: (_, current) =>
            current is UsersReady && current.notice != null && !current.noticeIsError,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text((state as UsersReady).notice!)));
        },
        builder: (context, state) => switch (state) {
          UsersLoading() => const Center(child: CircularProgressIndicator(color: turquoise)),
          UsersLoadFailed(:final message) => _LoadFailed(message: message),
          UsersReady(:final users) when users.isEmpty => const _Empty(),
          UsersReady(:final users) => _UserList(
              users: users,
              onEdit: (user) => _openForm(context, user: user),
              onDelete: (user) => _confirmDelete(context, user),
            ),
        },
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<User> users;
  final void Function(User) onEdit;
  final void Function(User) onDelete;

  const _UserList({required this.users, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          itemCount: users.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '${users.length} ${users.length == 1 ? 'USUARIO' : 'USUARIOS'}',
                  style: eyebrow.copyWith(color: turquoise),
                ),
              );
            }

            final user = users[index - 1];
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _Initials(name: user.name),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: deepAqua,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(fontSize: 13, color: teal.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: teal,
                      tooltip: 'Editar ${user.name}',
                      onPressed: () => onEdit(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: danger,
                      tooltip: 'Eliminar ${user.name}',
                      onPressed: () => onDelete(user),
                    ),
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

class _Initials extends StatelessWidget {
  final String name;

  const _Initials({required this.name});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: mist,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: mistEdge),
      ),
      child: Text(
        _initials,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: turquoise),
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
            Text('SIN USUARIOS', style: eyebrow.copyWith(color: turquoise)),
            const SizedBox(height: 10),
            Text(
              'Crea el primer usuario para poder registrar transferencias.',
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
              onPressed: () => context.read<UsersBloc>().add(const UsersRequested()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
