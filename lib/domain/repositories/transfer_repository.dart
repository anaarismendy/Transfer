import '../../core/result.dart';
import '../entities/transfer.dart';

abstract class TransferRepository {
  Future<Result<List<Transfer>>> getAll();

  Future<Result<Transfer>> create({
    required String sourceUserId,
    required String destinationUserId,
    required int amountInCents,
    String? description,
  });
}
