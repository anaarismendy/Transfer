import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/data/datasources/app_database.dart';
import 'package:prueba_tecnica/data/datasources/transfer_local_datasource.dart';
import 'package:prueba_tecnica/data/datasources/user_local_datasource.dart';
import 'package:prueba_tecnica/data/repositories/transfer_repository_impl.dart';
import 'package:prueba_tecnica/data/repositories/user_repository_impl.dart';
import 'package:prueba_tecnica/data/services/bcrypt_password_hasher.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';
import 'package:prueba_tecnica/domain/usecases/create_transfer.dart';
import 'package:prueba_tecnica/domain/usecases/get_transfers.dart';
import 'package:prueba_tecnica/domain/usecases/get_users.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
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
  });

  group('pantalla', () {
    late Database db;
    late TransfersBloc bloc;
    late UserRepository users;

    setUp(() async {
      db = await AppDatabase.openInMemory();
      users = UserRepositoryImpl(UserLocalDataSource(db));
      final transfers = TransferRepositoryImpl(TransferLocalDataSource(db));
      BcryptPasswordHasher();

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

    /// El cuerpo de testWidgets corre con reloj falso, asi que el I/O real de
    /// SQLite solo completa dentro de runAsync.
    Future<void> seedUsers(WidgetTester tester, {int count = 2}) => tester.runAsync(() async {
          await users.create(name: 'Ana', email: 'ana@test.com', passwordHash: 'h');
          if (count > 1) {
            await users.create(name: 'Luis', email: 'luis@test.com', passwordHash: 'h');
          }
        });

    Widget app() => BlocProvider.value(
          value: bloc,
          child: MaterialApp(theme: buildAppTheme(), home: const TransfersView()),
        );

    Future<void> waitFor(WidgetTester tester, bool Function(TransfersState) matcher) async {
      await tester.pump();
      if (!matcher(bloc.state)) {
        await tester.runAsync(
          () => bloc.stream.firstWhere(matcher).timeout(const Duration(seconds: 15)),
        );
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(app());
      bloc.add(const TransfersRequested());
      await waitFor(tester, (s) => s is TransfersReady);
    }

    testWidgets('sin movimientos invita a registrar el primero', (tester) async {
      await seedUsers(tester);
      await open(tester);

      expect(find.text('SIN MOVIMIENTOS'), findsOneWidget);
    });

    testWidgets('con menos de dos usuarios no deja abrir el formulario', (tester) async {
      await seedUsers(tester, count: 1);
      await open(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TransferFormPage), findsNothing);
      expect(find.text('Necesitas al menos dos usuarios para transferir'), findsOneWidget);
    });

    testWidgets('registra una transferencia y muestra el comprobante', (tester) async {
      await seedUsers(tester);
      await open(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<User>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<User>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Luis').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Valor'), '150000');
      await tester.enterText(find.widgetWithText(TextFormField, 'Descripcion'), 'Arriendo');
      await tester.tap(find.widgetWithText(FilledButton, 'Registrar transferencia'));
      await waitFor(tester, (s) => s is TransfersReady && s.created != null);
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptPage), findsOneWidget);
      expect(find.text('COMPROBANTE'), findsOneWidget);
      expect(find.text(r'$150.000'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Luis'), findsOneWidget);
      expect(find.text('Arriendo'), findsOneWidget);
    });

    testWidgets('el destino no ofrece al usuario elegido como origen', (tester) async {
      await seedUsers(tester);
      await open(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<User>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<User>).last);
      await tester.pumpAndSettle();

      expect(find.text('Luis'), findsOneWidget, reason: 'solo Luis puede ser destino');
    });

    testWidgets('valida origen, destino y valor', (tester) async {
      await seedUsers(tester);
      await open(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Registrar transferencia'));
      await tester.pump();

      expect(find.text('Selecciona el origen'), findsOneWidget);
      expect(find.text('Selecciona el destino'), findsOneWidget);
      expect(find.text('Escribe el valor'), findsOneWidget);
    });

    testWidgets('el historial muestra el movimiento con nombres y valor', (tester) async {
      await seedUsers(tester);
      await open(tester);
      final ready = bloc.state as TransfersReady;

      bloc.add(TransferSubmitted(
        sourceUserId: ready.users.first.id,
        destinationUserId: ready.users.last.id,
        amountInCents: 250000 * 100,
      ));
      await waitFor(tester, (s) => s is TransfersReady && s.transfers.length == 1);

      expect(find.text('1 MOVIMIENTO'), findsOneWidget);
      expect(find.textContaining('â†’'), findsOneWidget);
      expect(find.text(r'$250.000'), findsOneWidget);
    });
  });
}


