import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/receipt_page.dart';
import 'package:prueba_tecnica/presentation/pages/transfer_form_page.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;
  late TransfersBloc bloc;
  late User ana;

  setUp(() async {
    h = await Harness.inMemory();
    ana = await h.newUserRaw('Ana', 'ana@test.com');
    bloc = h.transfersBloc;
    addTearDown(bloc.close);
  });

  Future<void> addLuis(WidgetTester tester) =>
      tester.runAsync(() => h.newUserRaw('Luis', 'luis@test.com'));

  Future<void> openFlow(WidgetTester tester) async {
    usePhone(tester);
    await tester.pumpWidget(hostAppWith(bloc, TransferFormPage(me: ana)));
    bloc.add(const TransfersRequested());
    await waitForState(tester, bloc, (s) => s is TransfersReady);
  }

  Future<void> typeAmount(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
  }

  testWidgets('el origen aparece y se puede cambiar', (tester) async {
    await addLuis(tester);
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
    await addLuis(tester);
    await openFlow(tester);

    expect(find.text('Luis'), findsOneWidget);
    expect(find.text('ana@test.com'), findsNothing, reason: 'Ana es el origen');
  });

  testWidgets('sin otro usuario no hay a quien transferir', (tester) async {
    await openFlow(tester);

    expect(find.text('No se encontraron contactos'), findsOneWidget);
  });

  testWidgets('el valor en cero no deja continuar', (tester) async {
    await addLuis(tester);
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
    await addLuis(tester);
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
    await addLuis(tester);
    await openFlow(tester);

    await tester.tap(find.text('Luis'));
    await tester.pumpAndSettle();

    await typeAmount(tester, '150000');
    expect(find.text(r'$150.000'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Arriendo');
    await tester.tap(find.text('Confirmar transferencia'));
    await waitForState(
      tester,
      bloc,
      (s) => s is TransfersReady && s.created != null,
    );
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
}
