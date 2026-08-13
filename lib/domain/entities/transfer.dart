import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer.freezed.dart';

@freezed
abstract class Transfer with _$Transfer {
  const factory Transfer({
    required String id,
    required String sourceUserId,
    required String destinationUserId,
    required int amountInCents,
    required DateTime createdAt,
    String? description,
  }) = _Transfer;
}
