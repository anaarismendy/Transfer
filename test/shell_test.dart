import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/di/injection.dart';
import 'package:prueba_tecnica/core/format.dart';
import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/data/datasources/app_database.dart';
import 'package:prueba_tecnica/data/datasources/session_local_datasource.dart';
import 'package:prueba_tecnica/data/datasources/transfer_local_datasource.dart';
import 'package:prueba_tecnica/data/datasources/user_local_datasource.dart';
import 'package:prueba_tecnica/data/repositories/auth_repository_impl.dart';
import 'package:prueba_tecnica/data/repositories/transfer_repository_impl.dart';
import 'package:prueba_tecnica/data/repositories/user_repository_impl.dart';
import 'package:prueba_tecnica/data/services/bcrypt_password_hasher.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/opening_balance.dart';
import 'package:prueba_tecnica/domain/usecases/create_transfer.dart';
import 'package:prueba_tecnica/domain/usecases/create_user.dart';
import 'package:prueba_tecnica/domain/usecases/delete_user.dart';
import 'package:prueba_tecnica/domain/usecases/get_current_user.dart';
import 'package:prueba_tecnica/domain/usecases/get_transfers.dart';
import 'package:prueba_tecnica/domain/usecases/get_users.dart';
import 'package:prueba_tecnica/domain/usecases/login.dart';
import 'package:prueba_tecnica/domain/usecases/logout.dart';
import 'package:prueba_tecnica/domain/usecases/update_user.dart';
import 'package:prueba_tecnica/presentation/blocs/auth_bloc.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/home_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late AuthBloc authBloc;
  late User ana;

  setUp(() async {
    db = await AppDatabase.openInMemory();
    final hasher = BcryptPasswordHasher();
    final users = UserRepositoryImpl(UserLocalDataSource(db));
    final auth = AuthRepositoryImpl(SessionLocalDataSource(db));
    final transfers = TransferRepositoryImpl(TransferLocalDataSource(db));

    final created = await users.create(
      name: 'Ana Arismendy',
      email: 'ana@test.com',
      passwordHash: 'hash',
      balanceInCents: openingBalanceInCents,
    );
    ana = (created as Ok<User>).value;

    authBloc = AuthBloc(
      Login(users, auth, hasher),
      Logout(auth),
      GetCurrentUser(auth, users),
    );

    getIt.registerFactory<UsersBloc>(
      () => UsersBloc(
        GetUsers(users),
        CreateUser(users, hasher),
        UpdateUser(users, hasher),
        DeleteUser(users, auth),
      ),
    );
    getIt.registerFactory<TransfersBloc>(
      () => TransfersBloc(
        GetUsers(users),
        GetTransfers(transfers),
        CreateTransfer(transfers, users),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
    await authBloc.close();
    await db.close();
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider.value(
        value: authBloc,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: HomePage(user: ana),
        ),
      ),
    );
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
}
