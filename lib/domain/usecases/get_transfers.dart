import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';
import 'package:prueba_tecnica/domain/repositories/transfer_repository.dart';

@lazySingleton
class GetTransfers {
  final TransferRepository _transfers;
  GetTransfers(this._transfers);

  Future<Result<List<Transfer>>> call() => _transfers.getAll();
}
