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
import 'package:prueba_tecnica/domain/usecases/create_user.dart';
import 'package:prueba_tecnica/domain/usecases/delete_user.dart';
import 'package:prueba_tecnica/domain/usecases/get_users.dart';
import 'package:prueba_tecnica/domain/usecases/seed_default_user.dart';
import 'package:prueba_tecnica/domain/usecases/update_user.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/user_form_page.dart';
import 'package:prueba_tecnica/presentation/pages/users_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Recorre el CRUD sobre la pantalla real. Se inyecta el bloc a mano en vez
/// de usar get_it para que cada test tenga su propia base en memoria.
void main() {
  late Database db;
  late UsersBloc usersBloc;

  setUp(() async {
    db = await AppDatabase.openInMemory();
    final hasher = BcryptPasswordHasher();
    final users = UserRepositoryImpl(UserLocalDataSource(db));
    final auth = AuthRepositoryImpl(SessionLocalDataSource(db));

    await SeedDefaultUser(users, hasher)();

    usersBloc = UsersBloc(
      GetUsers(users),
      CreateUser(users, hasher),
      UpdateUser(users, hasher),
      DeleteUser(users, auth),
    );
  });

  tearDown(() async {
    await usersBloc.close();
    await db.close();
  });

  Widget app() => BlocProvider.value(
    value: usersBloc,
    child: MaterialApp(
      theme: buildAppTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Builder(
            builder: (inner) => TextButton(
              onPressed: () => Navigator.of(inner).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: usersBloc,
                    child: const Scaffold(body: UsersView()),
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );

  /// Espera el trabajo real (SQLite + bcrypt) que el reloj falso no avanza.
  Future<void> waitFor(
    WidgetTester tester,
    bool Function(UsersState) matcher,
  ) async {
    await tester.pump();
    if (!matcher(usersBloc.state)) {
      await tester.runAsync(
        () => usersBloc.stream
            .firstWhere(matcher)
            .timeout(const Duration(seconds: 15)),
      );
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openList(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('abrir'));
    await tester.pump();
    // No se usa pumpAndSettle: mientras carga hay un spinner que anima sin fin.
    await tester.pump(const Duration(milliseconds: 400));
    usersBloc.add(const UsersRequested());
    await waitFor(tester, (s) => s is UsersReady);
  }

  /// Los campos no tienen label dentro del input (el diseno lo pone encima),
  /// asi que se toman por posicion: nombre, correo, contrasena.
  Finder field(int index) => find.byType(TextFormField).at(index);

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    required String name,
    required String email,
    String password = 'Secreta123',
  }) async {
    await tester.enterText(field(0), name);
    await tester.enterText(field(1), email);
    await tester.enterText(field(2), password);
    await tester.pump();
  }

  testWidgets('lista el usuario semilla con su correo', (tester) async {
    await openList(tester);

    expect(find.text('Administrador'), findsOneWidget);
    expect(find.text(SeedDefaultUser.email), findsOneWidget);
  });

  testWidgets('crea un usuario desde el formulario', (tester) async {
    await openList(tester);
    await openForm(tester);
    expect(find.byType(UserFormPage), findsOneWidget);

    await fillForm(tester, name: 'Ana Arismendy', email: 'ana@test.com');
    await tester.tap(find.text('Guardar contacto'));
    await waitFor(tester, (s) => s is UsersReady && s.users.length == 2);
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byType(UserFormPage),
      findsNothing,
      reason: 'debe cerrarse al guardar',
    );
    expect(find.text('Ana Arismendy'), findsOneWidget);
  });

  testWidgets('el correo duplicado deja el formulario abierto con el error', (
    tester,
  ) async {
    await openList(tester);
    await openForm(tester);

    await fillForm(tester, name: 'Otro Admin', email: SeedDefaultUser.email);
    await tester.tap(find.text('Guardar contacto'));
    await waitFor(tester, (s) => s is UsersReady && s.noticeIsError);

    expect(
      find.byType(UserFormPage),
      findsOneWidget,
      reason: 'no debe perder lo escrito',
    );
    expect(find.text('Ya existe un usuario con ese correo'), findsWidgets);
    expect(
      find.text('Otro Admin'),
      findsOneWidget,
      reason: 'el nombre sigue en el campo',
    );
  });

  testWidgets('valida el formato del correo antes de guardar', (tester) async {
    await openList(tester);
    await openForm(tester);

    await fillForm(tester, name: 'Ana', email: 'no-es-correo');
    await tester.tap(find.text('Guardar contacto'));
    await tester.pump();

    expect(find.text('El correo no tiene un formato valido'), findsOneWidget);
    expect(find.byType(UserFormPage), findsOneWidget);
  });

  testWidgets('el boton no se habilita con el formulario vacio', (
    tester,
  ) async {
    await openList(tester);
    await openForm(tester);

    await tester.tap(find.text('Guardar contacto'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byType(UserFormPage),
      findsOneWidget,
      reason: 'no intento guardar',
    );
  });

  testWidgets('edita el nombre sin tocar la contrasena', (tester) async {
    await openList(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Nueva contrasena (opcional)'), findsOneWidget);

    await tester.enterText(field(0), 'Admin Principal');
    await tester.pump();
    await tester.tap(find.text('Guardar contacto'));
    await waitFor(
      tester,
      (s) => s is UsersReady && s.notice == 'Cambios guardados',
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Admin Principal'), findsOneWidget);
  });

  testWidgets('pide confirmacion en la fila y cancela sin borrar', (
    tester,
  ) async {
    await openList(tester);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('¿Eliminar a Administrador?'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('elimina un usuario cuando se confirma', (tester) async {
    await openList(tester);
    await openForm(tester);
    await fillForm(tester, name: 'Temporal', email: 'temp@test.com');
    await tester.tap(find.text('Guardar contacto'));
    await waitFor(tester, (s) => s is UsersReady && s.users.length == 2);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Si'));
    await waitFor(tester, (s) => s is UsersReady && s.users.length == 1);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Temporal'), findsNothing);
    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('la busqueda filtra por nombre', (tester) async {
    await openList(tester);
    await openForm(tester);
    await fillForm(tester, name: 'Ana Arismendy', email: 'ana@test.com');
    await tester.tap(find.text('Guardar contacto'));
    await waitFor(tester, (s) => s is UsersReady && s.users.length == 2);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextFormField).first, 'ana');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ana Arismendy'), findsOneWidget);
    expect(find.text('Administrador'), findsNothing);
  });
}
