import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/user.dart';
import '../models/user_mapper.dart';

/// Acceso crudo a Hive. Lanza si algo falla; traducir a Failure es trabajo
/// del repositorio. Esa es la separacion: aqui almacenamiento, alla errores.
@lazySingleton
class UserLocalDataSource {
  final Box _box;
  UserLocalDataSource(@Named('users') this._box);

  List<User> getAll() => _box.values.map((e) => userFromMap(e as Map)).toList();

  User? getById(String id) {
    final raw = _box.get(id);
    return raw == null ? null : userFromMap(raw as Map);
  }

  User? findByEmail(String email) {
    final target = email.trim().toLowerCase();
    for (final raw in _box.values) {
      final user = userFromMap(raw as Map);
      if (user.email.toLowerCase() == target) return user;
    }
    return null;
  }

  Future<void> save(User user) => _box.put(user.id, user.toMap());

  Future<void> delete(String id) => _box.delete(id);

  bool get isEmpty => _box.isEmpty;
}
