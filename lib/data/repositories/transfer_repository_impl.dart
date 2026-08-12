import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../../core/result.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/transfer_local_datasource.dart';

@LazySingleton(as: TransferRepository)
class TransferRepositoryImpl implements TransferRepository {
  final TransferLocalDataSource _local;
  TransferRepositoryImpl(this._local);

  @override
  Future<Result<List<Transfer>>> getAll() async {
    try {
      return Ok(_local.getAll());
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<Transfer>> create({
    required String sourceUserId,
    required String destinationUserId,
    required int amountInCents,
    String? description,
  }) async {
    try {
      final transfer = Transfer(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sourceUserId: sourceUserId,
        destinationUserId: destinationUserId,
        amountInCents: amountInCents,
        createdAt: DateTime.now(),
        description: description?.trim().isEmpty ?? true ? null : description!.trim(),
      );
      await _local.save(transfer);
      return Ok(transfer);
    } catch (_) {
      return const Err(StorageFailure());
    }
  }
}
