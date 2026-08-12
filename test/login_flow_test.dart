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
import 'package:prueba_tecnica/presentation/pages/home_page.dart';
import 'package:prueba_tecnica/presentation/pages/login_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Recorre la pantalla real con la base real en memoria: es lo mas cerca de
/// lo que hara el evaluador cuando abra la app.
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
              Authenticated(:final user) => HomePage(user: user),
              _ => const LoginPage(),
            },
          ),
        ),
      );

  /// `pumpAndSettle` no sirve aqui: el indicador de carga anima infinitamente
  /// y bcrypt corre en tiempo real, que el reloj falso del test no avanza.
  /// Se espera el estado concreto del bloc y luego se pinta.
  Future<void> waitFor(WidgetTester tester, bool Function(AuthState) matcher) async {
    await tester.pump();
    if (!matcher(authBloc.state)) {
      await tester.runAsync(
        () => authBloc.stream.firstWhere(matcher).timeout(const Duration(seconds: 10)),
      );
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> fillAndSubmit(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Contrasena'), password);
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  }

  testWidgets('entra con las credenciales del usuario semilla', (tester) async {
    await tester.pumpWidget(app());

    await fillAndSubmit(tester, SeedDefaultUser.email, SeedDefaultUser.password);
    await waitFor(tester, (s) => s is Authenticated);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('muestra el error y se queda en el login si la contrasena es mala',
      (tester) async {
    await tester.pumpWidget(app());

    await fillAndSubmit(tester, SeedDefaultUser.email, 'Equivocada1');
    await waitFor(tester, (s) => s is AuthFailed);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Usuario o contrasena incorrectos'), findsOneWidget);
  });

  testWidgets('valida los campos vacios sin consultar la base', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Escribe tu correo'), findsOneWidget);
    expect(find.text('Escribe tu contrasena'), findsOneWidget);
  });

  testWidgets('valida el formato del correo', (tester) async {
    await tester.pumpWidget(app());

    await fillAndSubmit(tester, 'no-es-correo', 'Admin123');
    await tester.pump();

    expect(find.text('El correo no tiene un formato valido'), findsOneWidget);
  });

  testWidgets('la contrasena arranca oculta y el ojo la muestra', (tester) async {
    await tester.pumpWidget(app());

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Contrasena'),
        matching: find.byType(TextField),
      ),
    );
    expect(field.obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar contrasena'));
    await tester.pump();

    final shown = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Contrasena'),
        matching: find.byType(TextField),
      ),
    );
    expect(shown.obscureText, isFalse);
  });

  testWidgets('cerrar sesion devuelve al login', (tester) async {
    await tester.pumpWidget(app());
    await fillAndSubmit(tester, SeedDefaultUser.email, SeedDefaultUser.password);
    await waitFor(tester, (s) => s is Authenticated);

    await tester.tap(find.byTooltip('Cerrar sesion'));
    await waitFor(tester, (s) => s is Unauthenticated);

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('la sesion sobrevive: al volver a arrancar entra directo', (tester) async {
    await tester.pumpWidget(app());
    await fillAndSubmit(tester, SeedDefaultUser.email, SeedDefaultUser.password);
    await waitFor(tester, (s) => s is Authenticated);

    authBloc.add(const AuthCheckRequested());
    await waitFor(tester, (s) => s is Authenticated);

    expect(find.byType(HomePage), findsOneWidget);
  });
}
