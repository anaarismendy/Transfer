import '../../domain/entities/transfer.dart';

extension TransferMapper on Transfer {
  Map<String, dynamic> toMap() => {
        'id': id,
        'sourceUserId': sourceUserId,
        'destinationUserId': destinationUserId,
        'amountInCents': amountInCents,
        // Se guarda como int en lugar de DateTime: independiente de zona
        // horaria y de como cada backend serialice fechas.
        'createdAt': createdAt.millisecondsSinceEpoch,
        'description': description,
      };
}

Transfer transferFromMap(Map<dynamic, dynamic> map) {
  final id = map['id'];
  final sourceUserId = map['sourceUserId'];
  final destinationUserId = map['destinationUserId'];
  final amountInCents = map['amountInCents'];
  final createdAt = map['createdAt'];
  final description = map['description'];

  if (id is! String ||
      sourceUserId is! String ||
      destinationUserId is! String ||
      amountInCents is! int ||
      createdAt is! int ||
      (description != null && description is! String)) {
    throw const FormatException('Registro de transferencia invalido');
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
