class Transfer {
  final String id;
  final String sourceUserId;
  final String destinationUserId;

  /// Dinero en la unidad minima (centavos), nunca `double`: los flotantes
  /// pierden precision al sumar y en un modulo de transferencias eso es un bug.
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
