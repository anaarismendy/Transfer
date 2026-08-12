import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

/// Tabla llave-valor de una sola fila. Sin backend no hay token real:
/// solo se guarda el id del usuario que inicio sesion.
@lazySingleton
class SessionLocalDataSource {
  static const _table = 'session';
  static const _key = 'userId';

  final Database _db;
  SessionLocalDataSource(this._db);

  /// `replace` para que iniciar sesion de nuevo sobrescriba en vez de fallar
  /// por llave primaria duplicada.
  Future<void> save(String userId) => _db.insert(
        _table,
        {'key': _key, 'value': userId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<String?> read() async {
    final rows = await _db.query(
      _table,
      where: 'key = ?',
      whereArgs: [_key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> clear() => _db.delete(_table, where: 'key = ?', whereArgs: [_key]);
}
