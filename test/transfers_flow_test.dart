import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/data/datasources/app_database.dart';
import 'package:prueba_tecnica/data/datasources/transfer_local_datasource.dart';
import 'package:prueba_tecnica/data/datasources/user_local_datasource.dart';
import 'package:prueba_tecnica/data/repositories/transfer_repository_impl.dart';
import 'package:prueba_tecnica/data/repositories/user_repository_impl.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/opening_balance.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';
import 'package:prueba_tecnica/domain/usecases/create_transfer.dart';
import 'package:prueba_tecnica/domain/usecases/get_transfers.dart';
import 'package:prueba_tecnica/domain/usecases/get_users.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/home_page.dart';
import 'package:prueba_tecnica/presentation/pages/receipt_page.dart';
import 'package:prueba_tecnica/presentation/pages/transfer_form_page.dart';
import 'package:prueba_tecnica/presentation/pages/transfers_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('formato', () {
    test('agrupa miles con punto, como en Colombia', () {
      expect(formatMoney(100), r'$1');
      expect(formatMoney(150000 * 100), r'$150.000');
      expect(formatMoney(1234567 * 100), r'$1.234.567');
    });

    test('un saldo negativo se agrupa bien', () {
      expect(formatMoney(-500000 * 100), r'-$500.000');
    });

    test('muestra centavos solo cuando existen', () {
      expect(formatMoney(500000), r'$5.000');
      expect(formatMoney(500050), r'$5.000,50');
    });

    test('convierte pesos escritos a centavos', () {
      expect(parsePesosToCents('150000'), 15000000);
      expect(parsePesosToCents('1.500'), 150000);
      expect(parsePesosToCents(''), isNull);
    });

    test('la fecha usa dos digitos', () {
      expect(formatDateTime(DateTime(2026, 8, 3, 9, 5)), '03/08/2026  09:05');
    });

    test('el teclado se muestra agrupado y con coma decimal', () {
      expect(formatKeypadAmount(''), '0');
      expect(formatKeypadAmount('150000'), '150.000');
      expect(formatKeypadAmount('1500.5'), '1.500,5');
    });

    test('el teclado convierte a centavos y rechaza el cero', () {
      expect(parseKeypadToCents('150000'), 15000000);
      expect(parseKeypadToCents('1500.5'), 150050);
      expect(parseKeypadToCents('1500.55'), 150055);
      expect(parseKeypadToCents('0'), isNull);
      expect(parseKeypadToCents(''), isNull);
    });

    test('la fecha relativa distingue hoy, ayer y el resto', () {
      final now = DateTime(2026, 8, 13, 15, 0);
      expect(
        formatRelative(DateTime(2026, 8, 13, 10, 32), now: now),
        'Hoy, 10:32',
      );
      expect(
        formatRelative(DateTime(2026, 8, 12, 18, 50), now: now),
        'Ayer, 18:50',
      );
      expect(
        formatRelative(DateTime(2026, 8, 10, 11, 5), now: now),
        '10/08, 11:05',
      );
    });
  });

  group('pantalla', () {
    late Database db;
    late TransfersBloc bloc;
    late UserRepository users;
    late User ana;
    late User luis;

    setUp(() async {
      db = await AppDatabase.openInMemory();
      users = UserRepositoryImpl(UserLocalDataSource(db));
      final transfers = TransferRepositoryImpl(TransferLocalDataSource(db));

      bloc = TransfersBloc(
        GetUsers(users),
        GetTransfers(transfers),
        CreateTransfer(transfers, users),
      );
    });

    tearDown(() async {
      await bloc.close();
      await db.close();
    });

    Future<User> newUser(String name, String email) async {
      final result = await users.create(
        name: name,
        email: email,
        passwordHash: 'h',
        balanceInCents: openingBalanceInCents,
      );
      return (result as Ok<User>).value;
    }

    /// El cuerpo de testWidgets corre con reloj falso, asi que el I/O real de
    /// SQLite solo completa dentro de runAsync.
    Future<void> seedUsers(WidgetTester tester, {int count = 2}) =>
        tester.runAsync(() async {
          ana = await newUser('Ana', 'ana@test.com');
          if (count > 1) luis = await newUser('Luis', 'luis@test.com');
        });

    Future<void> waitFor(
      WidgetTester tester,
      bool Function(TransfersState) matcher,
    ) async {
      await tester.pump();
      if (!matcher(bloc.state)) {
        await tester.runAsync(
          () => bloc.stream
              .firstWhere(matcher)
              .timeout(const Duration(seconds: 15)),
        );
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    Widget host(Widget child) => BlocProvider.value(
      value: bloc,
      child: MaterialApp(theme: buildAppTheme(), home: child),
    );

    /// El lienzo de prueba es 800x600 y el teclado queda fuera de pantalla, asi
    /// que se usa una ventana con forma de telefono.
    void usePhone(WidgetTester tester) {
      tester.view.physicalSize = const Size(430, 1240);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Future<void> openHistory(WidgetTester tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        host(Scaffold(body: TransfersView(currentUser: ana))),
      );
      bloc.add(const TransfersRequested());
      await waitFor(tester, (s) => s is TransfersReady);
    }

    Future<void> openFlow(WidgetTester tester) async {
      usePhone(tester);
      await tester.pumpWidget(host(TransferFormPage(me: ana)));
      bloc.add(const TransfersRequested());
      await waitFor(tester, (s) => s is TransfersReady);
    }

    Future<void> typeAmount(WidgetTester tester, String digits) async {
      for (final digit in digits.split('')) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
    }

    testWidgets('sin movimientos lo dice y no inventa filas', (tester) async {
      await seedUsers(tester);
      await openHistory(tester);

      expect(find.text('No hay movimientos'), findsOneWidget);
    });

    testWidgets('el origen aparece y se puede cambiar', (tester) async {
      await seedUsers(tester);
      await openFlow(tester);

      expect(find.text('Desde'), findsOneWidget);
      expect(
        find.text('Ana'),
        findsOneWidget,
        reason: 'la sesion es el origen por defecto',
      );
      expect(find.text('Cambiar'), findsOneWidget);
    });

    testWidgets('el destino no ofrece al usuario que va de origen', (
      tester,
    ) async {
      await seedUsers(tester);
      await openFlow(tester);

      expect(find.text('Luis'), findsOneWidget);
      expect(
        find.text('ana@test.com'),
        findsNothing,
        reason: 'Ana es el origen',
      );
    });

    testWidgets('sin otro usuario no hay a quien transferir', (tester) async {
      await seedUsers(tester, count: 1);
      await openFlow(tester);

      expect(find.text('No se encontraron contactos'), findsOneWidget);
    });

    testWidgets('el valor en cero no deja continuar', (tester) async {
      await seedUsers(tester);
      await openFlow(tester);

      await tester.tap(find.text('Luis'));
      await tester.pumpAndSettle();
      expect(find.text('Monto a enviar'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Confirmar transferencia'), findsNothing);
      expect(
        find.text('Monto a enviar'),
        findsOneWidget,
        reason: 'sigue en el teclado',
      );
    });

    testWidgets('el teclado borra el ultimo digito', (tester) async {
      await seedUsers(tester);
      await openFlow(tester);

      await tester.tap(find.text('Luis'));
      await tester.pumpAndSettle();
      await typeAmount(tester, '1500');
      expect(find.text(r'$1.500'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(find.text(r'$150'), findsOneWidget);
    });

    testWidgets('registra la transferencia y muestra el comprobante', (
      tester,
    ) async {
      await seedUsers(tester);
      await openFlow(tester);

      await tester.tap(find.text('Luis'));
      await tester.pumpAndSettle();

      await typeAmount(tester, '150000');
      expect(find.text(r'$150.000'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Arriendo');
      await tester.tap(find.text('Confirmar transferencia'));
      await waitFor(tester, (s) => s is TransfersReady && s.created != null);
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptPage), findsOneWidget);
      expect(find.text('¡Transferencia exitosa!'), findsOneWidget);
      expect(find.text('COMPROBANTE'), findsOneWidget);
      expect(
        find.text(r'$150.000'),
        findsOneWidget,
        reason: 'el valor del comprobante',
      );
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Luis'), findsOneWidget);
      expect(find.text('Arriendo'), findsOneWidget);
    });

    testWidgets('el historial muestra el movimiento como enviado', (
      tester,
    ) async {
      await seedUsers(tester);
      await openHistory(tester);

      bloc.add(
        TransferSubmitted(
          sourceUserId: ana.id,
          destinationUserId: luis.id,
          amountInCents: 250000 * 100,
        ),
      );
      await waitFor(
        tester,
        (s) => s is TransfersReady && s.transfers.length == 1,
      );

      expect(
        find.text('Luis'),
        findsOneWidget,
        reason: 'se ve la contraparte, no uno mismo',
      );
      expect(find.text(r'-$250.000'), findsOneWidget);
    });

    Future<void> openDashboard(WidgetTester tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: DashboardView(user: ana, onTab: (_) {}, onTransfer: (_) {}),
          ),
        ),
      );
      bloc.add(const TransfersRequested());
      await waitFor(tester, (s) => s is TransfersReady);
    }

    testWidgets(
      'el saldo arranca en el cupo de apertura y baja con lo enviado',
      (tester) async {
        await seedUsers(tester);
        await openDashboard(tester);

        expect(find.text(formatMoney(openingBalanceInCents)), findsOneWidget);

        bloc.add(
          TransferSubmitted(
            sourceUserId: ana.id,
            destinationUserId: luis.id,
            amountInCents: 250000 * 100,
          ),
        );
        await waitFor(
          tester,
          (s) => s is TransfersReady && s.transfers.length == 1,
        );

        expect(
          find.text(formatMoney(openingBalanceInCents - 250000 * 100)),
          findsOneWidget,
        );
      },
    );

    testWidgets('el ojo tapa el saldo', (tester) async {
      await seedUsers(tester);
      await openDashboard(tester);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.text(formatMoney(openingBalanceInCents)), findsNothing);
      expect(find.text('•••••••'), findsOneWidget);
    });

    testWidgets('el filtro de recibidos deja fuera lo que uno envio', (
      tester,
    ) async {
      await seedUsers(tester);
      await openHistory(tester);

      bloc.add(
        TransferSubmitted(
          sourceUserId: ana.id,
          destinationUserId: luis.id,
          amountInCents: 250000 * 100,
        ),
      );
      await waitFor(
        tester,
        (s) => s is TransfersReady && s.transfers.length == 1,
      );

      await tester.tap(find.text('Recibidos'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('No hay movimientos'), findsOneWidget);

      await tester.tap(find.text('Enviados'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(r'-$250.000'), findsOneWidget);
    });
  });
}
