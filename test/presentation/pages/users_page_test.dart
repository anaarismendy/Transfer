import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/domain/usecases/seed_default_user.dart';
import 'package:prueba_tecnica/presentation/blocs/users_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/user_form_page.dart';
import 'package:prueba_tecnica/presentation/pages/users_page.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;
  late UsersBloc bloc;

  setUp(() async {
    h = await Harness.inMemory();
    await h.seedDefaultUser();
    bloc = h.usersBloc;
    addTearDown(bloc.close);
  });

  Widget app() => hostAppWith(
    bloc,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const Scaffold(body: UsersView()),
              ),
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  );

  Future<void> openList(WidgetTester tester) async {
    usePhone(tester);
    await tester.pumpWidget(app());
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    bloc.add(const UsersRequested());
    await waitForState(tester, bloc, (s) => s is UsersReady);
  }

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
    await waitForState(
      tester,
      bloc,
      (s) => s is UsersReady && s.users.length == 2,
    );
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
    await waitForState(tester, bloc, (s) => s is UsersReady && s.noticeIsError);

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
    await waitForState(
      tester,
      bloc,
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
    await waitForState(
      tester,
      bloc,
      (s) => s is UsersReady && s.users.length == 2,
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Si'));
    await waitForState(
      tester,
      bloc,
      (s) => s is UsersReady && s.users.length == 1,
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Temporal'), findsNothing);
    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('la busqueda filtra por nombre', (tester) async {
    await openList(tester);
    await openForm(tester);
    await fillForm(tester, name: 'Ana Arismendy', email: 'ana@test.com');
    await tester.tap(find.text('Guardar contacto'));
    await waitForState(
      tester,
      bloc,
      (s) => s is UsersReady && s.users.length == 2,
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextFormField).first, 'ana');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ana Arismendy'), findsOneWidget);
    expect(find.text('Administrador'), findsNothing);
  });
}
