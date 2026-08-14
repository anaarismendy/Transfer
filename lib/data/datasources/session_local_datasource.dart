import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
class SessionLocalDataSource {
  static const _table = 'session';
  static const _key = 'userId';

  final Database _db;
  SessionLocalDataSource(this._db);

  Future<void> save(String userId) => _db.insert(_table, {
    'key': _key,
    'value': userId,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<String?> read() async {
    final rows = await _db.query(
      _table,
      where: 'key = ?',
      whereArgs: [_key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> clear() =>
      _db.delete(_table, where: 'key = ?', whereArgs: [_key]);
}
