import 'package:injectable/injectable.dart';

import '../../core/result.dart';
import '../entities/transfer.dart';
import '../repositories/transfer_repository.dart';

@lazySingleton
class GetTransfers {
  final TransferRepository _transfers;
  GetTransfers(this._transfers);

  Future<Result<List<Transfer>>> call() => _transfers.getAll();
}
