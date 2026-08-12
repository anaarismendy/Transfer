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
                        child: const UsersView(),
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
  Future<void> waitFor(WidgetTester tester, bool Function(UsersState) matcher) async {
    await tester.pump();
    if (!matcher(usersBloc.state)) {
      await tester.runAsync(
        () => usersBloc.stream.firstWhere(matcher).timeout(const Duration(seconds: 15)),
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

  testWidgets('lista el usuario semilla', (tester) async {
    await openList(tester);

    expect(find.text('Administrador'), findsOneWidget);
    expect(find.text('1 USUARIO'), findsOneWidget);
  });

  testWidgets('crea un usuario desde el formulario', (tester) async {
    await openList(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(UserFormPage), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Ana Arismendy');
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), 'ana@test.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contrasena'), 'Secreta123');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear usuario'));
    await waitFor(tester, (s) => s is UsersReady && s.users.length == 2);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(UserFormPage), findsNothing, reason: 'debe cerrarse al guardar');
    expect(find.text('Ana Arismendy'), findsOneWidget);
    expect(find.text('2 USUARIOS'), findsOneWidget);
  });

  testWidgets('el correo duplicado deja el formulario abierto con el error', (tester) async {
    await openList(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Otro Admin');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      SeedDefaultUser.email,
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Contrasena'), 'Secreta123');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear usuario'));
    await waitFor(tester, (s) => s is UsersReady && s.noticeIsError);

    expect(find.byType(UserFormPage), findsOneWidget, reason: 'no debe perder lo escrito');
    expect(find.text('Ya existe un usuario con ese correo'), findsOneWidget);
    expect(find.text('Otro Admin'), findsOneWidget, reason: 'el nombre sigue en el campo');
  });

  testWidgets('valida los campos del formulario', (tester) async {
    await openList(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Crear usuario'));
    await tester.pump();

    expect(find.text('El nombre es obligatorio'), findsOneWidget);
  });

  testWidgets('edita el nombre sin tocar la contrasena', (tester) async {
    await openList(tester);

    await tester.tap(find.byTooltip('Editar Administrador'));
    await tester.pumpAndSettle();

    expect(find.text('Dejala vacia para conservar la actual'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Admin Principal');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await waitFor(tester, (s) => s is UsersReady && s.notice == 'Cambios guardados');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Admin Principal'), findsOneWidget);
  });

  testWidgets('pide confirmacion antes de eliminar y cancela sin borrar', (tester) async {
    await openList(tester);

    await tester.tap(find.byTooltip('Eliminar Administrador'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Eliminar usuario'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('elimina un usuario cuando se confirma', (tester) async {
    await openList(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Temporal');
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), 'temp@test.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contrasena'), 'Secreta123');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear usuario'));
    await waitFor(tester, (s) => s is UsersReady && s.users.length == 2);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('Eliminar Temporal'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Eliminar'));
    await waitFor(tester, (s) => s is UsersReady && s.users.length == 1);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Temporal'), findsNothing);
    expect(find.text('1 USUARIO'), findsOneWidget);
  });
}

