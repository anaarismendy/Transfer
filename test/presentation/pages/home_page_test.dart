import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/di/injection.dart';
import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/opening_balance.dart';
import 'package:prueba_tecnica/presentation/blocs/auth_bloc.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/home_page.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;
  late User ana;

  setUp(() async {
    h = await Harness.inMemory();
    ana = await h.newUserRaw('Ana Arismendy', 'ana@test.com');
  });

  group('DashboardView', () {
    late TransfersBloc bloc;

    setUp(() {
      bloc = h.transfersBloc;
      addTearDown(bloc.close);
    });

    Future<void> open(WidgetTester tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        hostAppWith(
          bloc,
          Scaffold(
            body: DashboardView(user: ana, onTab: (_) {}, onTransfer: (_) {}),
          ),
        ),
      );
      bloc.add(const TransfersRequested());
      await waitForState(tester, bloc, (s) => s is TransfersReady);
    }

    testWidgets('el saldo arranca en el cupo y baja con lo enviado', (
      tester,
    ) async {
      final luis = await tester.runAsync(
        () => h.newUserRaw('Luis', 'luis@test.com'),
      );
      await open(tester);

      expect(find.text(formatMoney(openingBalanceInCents)), findsOneWidget);

      bloc.add(
        TransferSubmitted(
          sourceUserId: ana.id,
          destinationUserId: luis!.id,
          amountInCents: 250000 * 100,
        ),
      );
      await waitForState(
        tester,
        bloc,
        (s) => s is TransfersReady && s.transfers.length == 1,
      );

      expect(
        find.text(formatMoney(openingBalanceInCents - 250000 * 100)),
        findsOneWidget,
      );
    });

    testWidgets('el ojo tapa el saldo', (tester) async {
      await open(tester);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.text(formatMoney(openingBalanceInCents)), findsNothing);
      expect(find.text('•••••••'), findsOneWidget);
    });
  });

  group('HomePage', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = h.authBloc;
      addTearDown(authBloc.close);

      getIt.registerFactory<UsersBloc>(() => h.usersBloc);
      getIt.registerFactory<TransfersBloc>(() => h.transfersBloc);
      addTearDown(getIt.reset);
    });

    Future<void> open(WidgetTester tester) async {
      usePhone(tester);
      await tester.pumpWidget(hostAppWith(authBloc, HomePage(user: ana)));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('arranca en inicio con el saludo y el saldo', (tester) async {
      await open(tester);

      expect(find.text('Hola,'), findsOneWidget);
      expect(find.text('Ana Arismendy'), findsOneWidget);
      expect(find.text(formatMoney(openingBalanceInCents)), findsOneWidget);
    });

    testWidgets('la barra inferior cambia de pestana', (tester) async {
      await open(tester);

      await tester.tap(find.text('Historial').last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('No hay movimientos'), findsOneWidget);

      await tester.tap(find.text('Contactos').last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('ana@test.com'), findsOneWidget);

      await tester.tap(find.text('Perfil').last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Cerrar sesion'), findsOneWidget);
    });

    testWidgets('el boton central abre el flujo de transferencia', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byIcon(Icons.arrow_forward_rounded).last);
      await tester.pumpAndSettle();

      expect(find.text('Transferir'), findsOneWidget);
      expect(find.text('Desde'), findsOneWidget);
      expect(find.text('No se encontraron contactos'), findsOneWidget);
    });

    testWidgets('cerrar sesion avisa al AuthBloc', (tester) async {
      await open(tester);

      await tester.tap(find.text('Perfil').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Cerrar sesion'));
      await tester.runAsync(
        () => authBloc.stream
            .firstWhere((s) => s is Unauthenticated)
            .timeout(const Duration(seconds: 10)),
      );

      expect(authBloc.state, isA<Unauthenticated>());
    });
  });
}
