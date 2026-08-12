import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/transfer.dart';
import '../models/transfer_mapper.dart';

/// No hay update ni delete a proposito: una transferencia es un hecho
/// historico. Un movimiento de dinero no se edita, se compensa con otro.
@lazySingleton
class TransferLocalDataSource {
  static const _table = 'transfers';

  final Database _db;
  TransferLocalDataSource(this._db);

  /// Mas recientes primero, resuelto por el indice idx_transfers_created_at.
  ///
  /// El `rowid` desempata: el reloj de Windows tiene resolucion de
  /// milisegundos, asi que dos transferencias seguidas pueden compartir
  /// `created_at` y sin el desempate el orden seria arbitrario.
  Future<List<Transfer>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'created_at DESC, rowid DESC');
    return rows.map(transferFromRow).toList();
  }

  Future<void> insert(Transfer transfer) => _db.insert(_table, transfer.toRow());
}
