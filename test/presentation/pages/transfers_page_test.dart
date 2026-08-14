import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/presentation/blocs/transfers_bloc.dart';
import 'package:prueba_tecnica/presentation/pages/transfers_page.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;
  late TransfersBloc bloc;
  late User ana;
  late User luis;

  setUp(() async {
    h = await Harness.inMemory();
    ana = await h.newUserRaw('Ana', 'ana@test.com');
    luis = await h.newUserRaw('Luis', 'luis@test.com');
    bloc = h.transfersBloc;
    addTearDown(bloc.close);
  });

  Future<void> openHistory(WidgetTester tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      hostAppWith(bloc, Scaffold(body: TransfersView(currentUser: ana))),
    );
    bloc.add(const TransfersRequested());
    await waitForState(tester, bloc, (s) => s is TransfersReady);
  }

  Future<void> sendOne(WidgetTester tester) async {
    bloc.add(
      TransferSubmitted(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 250000 * 100,
      ),
    );
    await waitForState(
      tester,
      bloc,
      (s) => s is TransfersReady && s.transfers.length == 1,
    );
  }

  testWidgets('sin movimientos lo dice y no inventa filas', (tester) async {
    await openHistory(tester);

    expect(find.text('No hay movimientos'), findsOneWidget);
  });

  testWidgets('muestra el movimiento como enviado', (tester) async {
    await openHistory(tester);
    await sendOne(tester);

    expect(
      find.text('Luis'),
      findsOneWidget,
      reason: 'se ve la contraparte, no uno mismo',
    );
    expect(find.text(r'-$250.000'), findsOneWidget);
  });

  testWidgets('una transferencia entre terceros no aparece como recibida', (
    tester,
  ) async {
    final carlos = await tester.runAsync(
      () => h.newUserRaw('Carlos', 'carlos@test.com'),
    );
    await openHistory(tester);

    bloc.add(
      TransferSubmitted(
        sourceUserId: luis.id,
        destinationUserId: carlos!.id,
        amountInCents: 90000 * 100,
      ),
    );
    await waitForState(
      tester,
      bloc,
      (s) => s is TransfersReady && s.transfers.length == 1,
    );

    expect(
      find.text(r'+$90.000'),
      findsNothing,
      reason: 'Ana no recibio nada: el movimiento es entre otros dos',
    );
    expect(find.text('No hay movimientos'), findsOneWidget);
  });

  testWidgets('el filtro de recibidos deja fuera lo que uno envio', (
    tester,
  ) async {
    await openHistory(tester);
    await sendOne(tester);

    await tester.tap(find.text('Recibidos'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No hay movimientos'), findsOneWidget);

    await tester.tap(find.text('Enviados'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(r'-$250.000'), findsOneWidget);
  });
}
