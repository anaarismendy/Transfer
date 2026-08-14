import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/theme.dart';
import 'package:prueba_tecnica/data/datasources/app_database.dart';
import 'package:prueba_tecnica/data/datasources/session_local_datasource.dart';
import 'package:prueba_tecnica/data/datasources/user_local_datasource.dart';
import 'package:prueba_tecnica/data/repositories/auth_repository_impl.dart';
import 'package:prueba_tecnica/data/repositories/user_repository_impl.dart';
import 'package:prueba_tecnica/data/services/bcrypt_password_hasher.dart';
import 'package:prueba_tecnica/domain/usecases/get_current_user.dart';
import 'package:prueba_tecnica/domain/usecases/login.dart';
import 'package:prueba_tecnica/domain/usecases/logout.dart';
import 'package:prueba_tecnica/domain/usecases/seed_default_user.dart';
import 'package:prueba_tecnica/presentation/blocs/auth_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/login_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late AuthBloc authBloc;

  setUp(() async {
    db = await AppDatabase.openInMemory();
    final hasher = BcryptPasswordHasher();
    final users = UserRepositoryImpl(UserLocalDataSource(db));
    final auth = AuthRepositoryImpl(SessionLocalDataSource(db));

    await SeedDefaultUser(users, hasher)();

    authBloc = AuthBloc(
      Login(users, auth, hasher),
      Logout(auth),
      GetCurrentUser(auth, users),
    );
  });

  tearDown(() async {
    await authBloc.close();
    await db.close();
  });

  Widget app() => BlocProvider.value(
    value: authBloc,
    child: MaterialApp(
      theme: buildAppTheme(),
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) => switch (state) {
          Authenticated(:final user) => Scaffold(
            body: Center(child: Text(user.name)),
          ),
          _ => const LoginPage(),
        },
      ),
    ),
  );

  Future<void> waitFor(
    WidgetTester tester,
    bool Function(AuthState) matcher,
  ) async {
    await tester.pump();
    if (!matcher(authBloc.state)) {
      await tester.runAsync(
        () => authBloc.stream
            .firstWhere(matcher)
            .timeout(const Duration(seconds: 10)),
      );
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> fillAndSubmit(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.enterText(find.byType(TextFormField).last, password);
    await tester.pump();
    await tester.tap(find.text('Iniciar sesion'));
  }

  testWidgets('entra con las credenciales del usuario semilla', (tester) async {
    await tester.pumpWidget(app());

    await fillAndSubmit(
      tester,
      SeedDefaultUser.email,
      SeedDefaultUser.password,
    );
    await waitFor(tester, (s) => s is Authenticated);

    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets(
    'muestra el error y se queda en el login si la contrasena es mala',
    (tester) async {
      await tester.pumpWidget(app());

      await fillAndSubmit(tester, SeedDefaultUser.email, 'Equivocada1');
      await waitFor(tester, (s) => s is AuthFailed);

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Usuario o contrasena incorrectos'), findsOneWidget);
    },
  );

  testWidgets('con los campos vacios el boton no consulta la base', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Iniciar sesion'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      authBloc.state,
      isA<AuthUnknown>(),
      reason: 'no llego a intentar el login',
    );
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('valida el formato del correo', (tester) async {
    await tester.pumpWidget(app());

    await fillAndSubmit(tester, 'no-es-correo', 'Admin123');
    await tester.pump();

    expect(find.text('El correo no tiene un formato valido'), findsOneWidget);
    expect(authBloc.state, isA<AuthUnknown>());
  });

  testWidgets('la contrasena arranca oculta y el ojo la muestra', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    TextField passwordField() => tester.widget<TextField>(
      find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(TextField),
      ),
    );

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(passwordField().obscureText, isFalse);
  });

  testWidgets('cerrar sesion devuelve al login', (tester) async {
    await tester.pumpWidget(app());
    await fillAndSubmit(
      tester,
      SeedDefaultUser.email,
      SeedDefaultUser.password,
    );
    await waitFor(tester, (s) => s is Authenticated);

    authBloc.add(const LogoutRequested());
    await waitFor(tester, (s) => s is Unauthenticated);

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('la sesion sobrevive: al volver a arrancar entra directo', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await fillAndSubmit(
      tester,
      SeedDefaultUser.email,
      SeedDefaultUser.password,
    );
    await waitFor(tester, (s) => s is Authenticated);

    authBloc.add(const AuthCheckRequested());
    await waitFor(tester, (s) => s is Authenticated);

    expect(find.text('Administrador'), findsOneWidget);
  });
}
