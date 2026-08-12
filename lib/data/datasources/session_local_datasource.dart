import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SessionLocalDataSource {
  static const _key = 'userId';

  final Box _box;
  SessionLocalDataSource(@Named('session') this._box);

  Future<void> save(String userId) => _box.put(_key, userId);

  String? read() => _box.get(_key) as String?;

  Future<void> clear() => _box.delete(_key);
}
