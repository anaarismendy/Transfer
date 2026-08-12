class User {
  final String id;
  final String name;
  final String email;
  final String passwordHash;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
  });

  User copyWith({String? name, String? email, String? passwordHash}) => User(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
      );
}
