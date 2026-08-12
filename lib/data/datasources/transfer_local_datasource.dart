import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/transfer.dart';
import '../models/transfer_mapper.dart';

@lazySingleton
class TransferLocalDataSource {
  final Box _box;
  TransferLocalDataSource(@Named('transfers') this._box);

  /// Mas recientes primero: es el orden en que se muestran en el historial.
  List<Transfer> getAll() {
    final all = _box.values.map((e) => transferFromMap(e as Map)).toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  Future<void> save(Transfer transfer) => _box.put(transfer.id, transfer.toMap());
}
