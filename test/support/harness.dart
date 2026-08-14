import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/errors/failures.dart';
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
import 'package:prueba_tecnica/domain/usecases/seed_default_user.dart';
import 'package:prueba_tecnica/domain/usecases/update_user.dart';
import 'package:prueba_tecnica/presentation/blocs/auth_bloc.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Failure? failureOf(Result<Object?> result) =>
    result.fold((f) => f, (_) => null);

T valueOf<T>(Result<T> result) =>
    result.fold((f) => throw StateError(f.message), (value) => value);

class Harness {
  final Database db;
  final BcryptPasswordHasher hasher;
  final UserRepositoryImpl users;
  final TransferRepositoryImpl transfers;
  final AuthRepositoryImpl auth;

  Harness._(this.db)
    : hasher = BcryptPasswordHasher(),
      users = UserRepositoryImpl(UserLocalDataSource(db)),
      transfers = TransferRepositoryImpl(TransferLocalDataSource(db)),
      auth = AuthRepositoryImpl(SessionLocalDataSource(db));

  static Future<Harness> inMemory() async {
    final db = await AppDatabase.openInMemory();
    addTearDown(() async {
      try {
        await db.close();
      } catch (_) {}
    });
    return Harness._(db);
  }

  Login get login => Login(users, auth, hasher);
  Logout get logout => Logout(auth);
  GetCurrentUser get getCurrentUser => GetCurrentUser(auth, users);
  GetUsers get getUsers => GetUsers(users);
  CreateUser get createUser => CreateUser(users, hasher);
  UpdateUser get updateUser => UpdateUser(users, hasher);
  DeleteUser get deleteUser => DeleteUser(users, auth);
  CreateTransfer get createTransfer => CreateTransfer(transfers, users);
  GetTransfers get getTransfers => GetTransfers(transfers);
  SeedDefaultUser get seedDefaultUser => SeedDefaultUser(users, hasher);

  AuthBloc get authBloc => AuthBloc(login, logout, getCurrentUser);

  UsersBloc get usersBloc =>
      UsersBloc(getUsers, createUser, updateUser, deleteUser);

  TransfersBloc get transfersBloc =>
      TransfersBloc(getUsers, getTransfers, createTransfer);

  Future<User> newUser({
    String name = 'Ana',
    String email = 'ana@test.com',
    String password = 'Secreta123',
  }) async =>
      valueOf(await createUser(name: name, email: email, password: password));

  Future<User> newUserRaw(String name, String email) async => valueOf(
    await users.create(
      name: name,
      email: email,
      passwordHash: 'hash',
      balanceInCents: openingBalanceInCents,
    ),
  );

  Future<int> balanceOf(String id) async =>
      valueOf(await users.getById(id))!.balanceInCents;
}

Widget hostApp(Widget home) => MaterialApp(theme: buildAppTheme(), home: home);

Widget hostAppWith<B extends StateStreamableSource<Object?>>(
  B bloc,
  Widget home,
) => BlocProvider<B>.value(value: bloc, child: hostApp(home));

void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 1240);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> waitForState<S>(
  WidgetTester tester,
  BlocBase<S> bloc,
  bool Function(S) matcher,
) async {
  await tester.pump();
  if (!matcher(bloc.state)) {
    await tester.runAsync(
      () =>
          bloc.stream.firstWhere(matcher).timeout(const Duration(seconds: 15)),
    );
  }
  await tester.pump(const Duration(milliseconds: 400));
}
