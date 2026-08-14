import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';
import 'package:prueba_tecnica/domain/repositories/transfer_repository.dart';
import 'package:prueba_tecnica/data/datasources/transfer_local_datasource.dart';

@LazySingleton(as: TransferRepository)
class TransferRepositoryImpl implements TransferRepository {
  final TransferLocalDataSource _local;
  TransferRepositoryImpl(this._local);

  @override
  Future<Result<List<Transfer>>> getAll() async {
    try {
      return Ok(await _local.getAll());
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
    final trimmed = description?.trim();
    final transfer = Transfer(
      id: const Uuid().v4(),
      sourceUserId: sourceUserId,
      destinationUserId: destinationUserId,
      amountInCents: amountInCents,
      createdAt: DateTime.now(),
      description: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );

    try {
      await _local.insertAndMoveBalances(transfer);
      return Ok(transfer);
    } on DatabaseException catch (e) {
      // El CHECK con nombre es lo que distingue "no le alcanza" de cualquier
      // otro fallo de base.
      return e.toString().contains('balance_not_negative')
          ? const Err(InsufficientFundsFailure())
          : const Err(StorageFailure());
    } catch (_) {
      return const Err(StorageFailure());
    }
  }
}
