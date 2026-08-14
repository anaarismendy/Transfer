import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

import 'package:prueba_tecnica/data/models/transfer_mapper.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';

@lazySingleton
class TransferLocalDataSource {
  static const _table = 'transfers';

  final Database _db;
  TransferLocalDataSource(this._db);

  Future<List<Transfer>> getAll() async {
    final rows = await _db.query(
      _table,
      orderBy: 'created_at DESC, rowid DESC',
    );
    return rows.map(transferFromRow).toList();
  }

  /// Debitar, acreditar y registrar son un solo hecho: o pasan los tres o no
  /// pasa ninguno. Si el debito deja el saldo en negativo, el CHECK de la tabla
  /// lanza y la transaccion se deshace completa, incluido el movimiento.
  Future<void> insertAndMoveBalances(Transfer transfer) => _db.transaction((
    txn,
  ) async {
    await txn.rawUpdate(
      'UPDATE users SET balance_in_cents = balance_in_cents - ? WHERE id = ?',
      [transfer.amountInCents, transfer.sourceUserId],
    );
    await txn.rawUpdate(
      'UPDATE users SET balance_in_cents = balance_in_cents + ? WHERE id = ?',
      [transfer.amountInCents, transfer.destinationUserId],
    );
    await txn.insert(_table, transfer.toRow());
  });
}
