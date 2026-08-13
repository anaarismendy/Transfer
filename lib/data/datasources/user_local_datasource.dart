import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/data/models/user_mapper.dart';

@lazySingleton
class UserLocalDataSource {
  static const _table = 'users';

  final Database _db;
  UserLocalDataSource(this._db);

  Future<List<User>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'name COLLATE NOCASE');
    return rows.map(userFromRow).toList();
  }

  Future<User?> getById(String id) async {
    final rows = await _db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : userFromRow(rows.first);
  }

  Future<User?> findByEmail(String email) async {
    final rows = await _db.query(
      _table,
      where: 'email = ?',
      whereArgs: [email.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : userFromRow(rows.first);
  }

  Future<void> insert(User user) => _db.insert(_table, user.toRow());

  Future<int> update(User user) =>
      _db.update(_table, user.toRow(), where: 'id = ?', whereArgs: [user.id]);

  Future<int> delete(String id) => _db.delete(_table, where: 'id = ?', whereArgs: [id]);

  Future<int> count() async =>
      Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM $_table')) ?? 0;
}
