import '../../domain/entities/transfer.dart';

extension TransferMapper on Transfer {
  Map<String, Object?> toRow() => {
        'id': id,
        'source_user_id': sourceUserId,
        'destination_user_id': destinationUserId,
        'amount_in_cents': amountInCents,
        'description': description,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}

Transfer transferFromRow(Map<String, Object?> row) {
  final id = row['id'];
  final sourceUserId = row['source_user_id'];
  final destinationUserId = row['destination_user_id'];
  final amountInCents = row['amount_in_cents'];
  final createdAt = row['created_at'];
  final description = row['description'];

  if (id is! String ||
      sourceUserId is! String ||
      destinationUserId is! String ||
      amountInCents is! int ||
      createdAt is! int ||
      (description != null && description is! String)) {
    throw const FormatException('Fila de transferencia invalida');
  }

  return Transfer(
    id: id,
    sourceUserId: sourceUserId,
    destinationUserId: destinationUserId,
    amountInCents: amountInCents,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    description: description as String?,
  );
}
