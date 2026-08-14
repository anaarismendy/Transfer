import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prueba_tecnica/core/di/injection.dart';
import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/presentation/blocs/auth_bloc.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/transfer_form_page.dart';
import 'package:prueba_tecnica/presentation/pages/transfers_page.dart';
import 'package:prueba_tecnica/presentation/pages/users_page.dart';
import 'package:prueba_tecnica/presentation/widgets/movement_row.dart';
import 'package:prueba_tecnica/presentation/widgets/soft.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<UsersBloc>()..add(const UsersRequested()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<TransfersBloc>()..add(const TransfersRequested()),
        ),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          body: ScreenBackground(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IndexedStack(
                    index: _index,
                    children: [
                      DashboardView(
                        user: widget.user,
                        onTab: (i) => setState(() => _index = i),
                        onTransfer: (contact) =>
                            _openTransfer(context, contact),
                      ),
                      const UsersView(),
                      TransfersView(currentUser: widget.user),
                      ProfileView(user: widget.user),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _TabBar(
                    index: _index,
                    onTab: (i) => setState(() => _index = i),
                    onTransfer: () => _openTransfer(context, null),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTransfer(BuildContext context, User? contact) {
    final bloc = context.read<TransfersBloc>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: TransferFormPage(me: widget.user, contact: contact),
        ),
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  final User user;
  final void Function(int index) onTab;
  final void Function(User? contact) onTransfer;

  const DashboardView({
    super.key,
    required this.user,
    required this.onTab,
    required this.onTransfer,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _showBalance = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransfersBloc, TransfersState>(
      builder: (context, state) {
        final ready = state is TransfersReady ? state : null;
        final me = ready?.userById(widget.user.id) ?? widget.user;

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, tabBarGap),
            children: [
              _header(context),
              const SizedBox(height: 22),
              _balanceCard(me),
              const SizedBox(height: 22),
              _quickActions(),
              const SizedBox(height: 26),
              if (ready != null) ...[
                _frequentContacts(ready),
                const SizedBox(height: 26),
                SectionTitle(
                  text: 'Ultimos movimientos',
                  action: GestureDetector(
                    onTap: () => widget.onTab(2),
                    child: const Text(
                      'Ver todo',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: violet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _recentMovements(ready),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        BrandAvatar(name: widget.user.name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hola,',
                style: TextStyle(fontSize: 12.5, color: muted),
              ),
              Text(
                widget.user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
        SoftCircleButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tienes notificaciones')),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: mutedWarm,
            size: 21,
          ),
        ),
      ],
    );
  }

  Widget _balanceCard(User me) {
    final digits = me.id.replaceAll('-', '');
    final last4 = digits.length > 4
        ? digits.substring(digits.length - 4)
        : digits;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: brandRaised(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo disponible',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showBalance = !_showBalance),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _showBalance
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _showBalance ? formatMoney(me.balanceInCents) : '•••••••',
            style: tabular.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuenta de ahorros •$last4',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      (
        Icons.arrow_forward_rounded,
        'Transferir',
        violet,
        () => widget.onTransfer(null),
      ),
      (
        Icons.people_outline_rounded,
        'Contactos',
        skyBlue,
        () => widget.onTab(1),
      ),
      (Icons.access_time_rounded, 'Historial', violet, () => widget.onTab(2)),
      (Icons.person_outline_rounded, 'Perfil', skyBlue, () => widget.onTab(3)),
    ];

    return Row(
      children: [
        for (final (icon, label, color, onTap) in actions)
          Expanded(
            child: Column(
              children: [
                SoftCircleButton(
                  size: 52,
                  onPressed: onTap,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _frequentContacts(TransfersReady ready) {
    final counts = <String, int>{};
    for (final t in ready.transfers) {
      if (t.sourceUserId == widget.user.id) {
        counts.update(t.destinationUserId, (v) => v + 1, ifAbsent: () => 1);
      }
      if (t.destinationUserId == widget.user.id) {
        counts.update(t.sourceUserId, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final contacts = ready.users.where((u) => u.id != widget.user.id).toList()
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));

    if (contacts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: 'Contactos frecuentes'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final contact in contacts.take(5))
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GestureDetector(
                    onTap: () => widget.onTransfer(contact),
                    child: SizedBox(
                      width: 62,
                      child: Column(
                        children: [
                          Avatar(
                            name: contact.name,
                            seed: contact.id,
                            size: 46,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            contact.name.split(' ').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recentMovements(TransfersReady ready) {
    final mine = ready.movementsOf(widget.user.id);

    if (mine.isEmpty) {
      return const SoftCard(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Center(
            child: Text(
              'Sin movimientos',
              style: TextStyle(fontSize: 13, color: muted),
            ),
          ),
        ),
      );
    }

    return SoftList(
      children: [
        for (final transfer in mine.take(3))
          MovementRow(
            transfer: transfer,
            currentUserId: widget.user.id,
            counterpartName: ready.nameOf(
              transfer.sourceUserId == widget.user.id
                  ? transfer.destinationUserId
                  : transfer.sourceUserId,
            ),
          ),
      ],
    );
  }
}

class ProfileView extends StatelessWidget {
  final User user;

  const ProfileView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, tabBarGap),
        children: [
          const PageHeading(text: 'Perfil'),
          const SizedBox(height: 22),
          Column(
            children: [
              BrandAvatar(name: user.name, size: 78),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              Text(
                user.email,
                style: const TextStyle(fontSize: 12.5, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SoftButton(
            label: 'Cerrar sesion',
            color: rose,
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int index;
  final void Function(int index) onTab;
  final VoidCallback onTransfer;

  const _TabBar({
    required this.index,
    required this.onTab,
    required this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: 14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: bgTop.withValues(alpha: 0.94),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA094C7).withValues(alpha: 0.15),
            offset: const Offset(0, -6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          _item(Icons.home_outlined, 'Inicio', 0),
          _item(Icons.people_outline_rounded, 'Contactos', 1),
          Transform.translate(
            offset: const Offset(0, -26),
            child: GestureDetector(
              onTap: onTransfer,
              child: Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: brandGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: bgTop, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8278C3).withValues(alpha: 0.45),
                      offset: const Offset(4, 6),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          _item(Icons.access_time_rounded, 'Historial', 2),
          _item(Icons.person_outline_rounded, 'Perfil', 3),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, int target) {
    final active = index == target;
    final color = active ? violet : tabIdle;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTab(target),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
