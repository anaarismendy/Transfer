import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/di/injection.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/user_form_page.dart';
import 'package:prueba_tecnica/presentation/widgets/soft.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UsersBloc>()..add(const UsersRequested()),
      child: const Scaffold(body: ScreenBackground(child: UsersView())),
    );
  }
}

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  String _search = '';
  String? _confirmDeleteId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersBloc, UsersState>(
      listenWhen: (_, current) =>
          current is UsersReady && current.notice != null,
      listener: (context, state) {
        final ready = state as UsersReady;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ready.notice!),
            backgroundColor: ready.noticeIsError ? sentInk : ink,
          ),
        );
      },
      builder: (context, state) => SafeArea(
        bottom: false,
        child: switch (state) {
          UsersLoading() => const Center(
            child: CircularProgressIndicator(color: violet),
          ),
          UsersLoadFailed(:final message) => _failed(message),
          UsersReady(:final users) => _list(context, users),
        },
      ),
    );
  }

  Widget _failed(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: sentInk, fontSize: 14),
      ),
    ),
  );

  Widget _list(BuildContext context, List<User> users) {
    final query = _search.trim().toLowerCase();
    final visible = query.isEmpty
        ? users
        : users
              .where(
                (u) =>
                    u.name.toLowerCase().contains(query) ||
                    u.email.toLowerCase().contains(query),
              )
              .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, tabBarGap),
      children: [
        PageHeading(
          text: 'Contactos',
          action: GestureDetector(
            onTap: () => _openForm(context, null),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8278C3).withValues(alpha: 0.40),
                    offset: const Offset(4, 5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SoftField(
          hint: 'Buscar contacto',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 18),
        if (visible.isEmpty)
          const SoftCard(
            child: Padding(
              padding: EdgeInsets.all(30),
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
              for (final user in visible)
                _confirmDeleteId == user.id
                    ? _confirmRow(user)
                    : _row(context, user),
            ],
          ),
      ],
    );
  }

  Widget _row(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          _tinyButton(
            icon: Icons.edit_outlined,
            color: violet,
            onTap: () => _openForm(context, user),
          ),
          const SizedBox(width: 8),
          _tinyButton(
            icon: Icons.delete_outline_rounded,
            color: rose,
            onTap: () => setState(() => _confirmDeleteId = user.id),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '¿Eliminar a ${user.name}?',
              style: const TextStyle(fontSize: 13.5, color: ink),
            ),
          ),
          _chipButton(
            label: 'Si',
            background: rose,
            foreground: Colors.white,
            onTap: () {
              context.read<UsersBloc>().add(UserRemoved(user.id));
              setState(() => _confirmDeleteId = null);
            },
          ),
          const SizedBox(width: 8),
          _chipButton(
            label: 'No',
            background: violet.withValues(alpha: 0.15),
            foreground: inkSoft,
            onTap: () => setState(() => _confirmDeleteId = null),
          ),
        ],
      ),
    );
  }

  Widget _tinyButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    ),
  );

  Widget _chipButton({
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  void _openForm(BuildContext context, User? user) {
    setState(() => _confirmDeleteId = null);
    final bloc = context.read<UsersBloc>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: UserFormPage(user: user),
        ),
      ),
    );
  }
}
