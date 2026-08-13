import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';

abstract class TransferRepository {
  Future<Result<List<Transfer>>> getAll();

  Future<Result<Transfer>> create({
    required String sourceUserId,
    required String destinationUserId,
    required int amountInCents,
    String? description,
  });
}
