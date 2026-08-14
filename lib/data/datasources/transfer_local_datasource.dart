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
