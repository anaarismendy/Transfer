class Transfer {
  final String id;
  final String sourceUserId;
  final String destinationUserId;

  final int amountInCents;

  final String? description;
  final DateTime createdAt;

  const Transfer({
    required this.id,
    required this.sourceUserId,
    required this.destinationUserId,
    required this.amountInCents,
    required this.createdAt,
    this.description,
  });
}
