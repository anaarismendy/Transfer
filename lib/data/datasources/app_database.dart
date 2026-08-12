import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Abre la base y define el esquema. Es el unico archivo con SQL de estructura.
class AppDatabase {
  static const _fileName = 'prueba_tecnica.db';
  static const _version = 1;

  static Future<Database> open() async {
    // sqflite trae SQLite nativo en Android/iOS/macOS; en Windows y Linux
    // hay que usar el motor por FFI.
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    return openDatabase(
      p.join(await getDatabasesPath(), _fileName),
      version: _version,
      onConfigure: _configure,
      onCreate: _createSchema,
    );
  }

  /// Misma base, mismo esquema, sin tocar disco. Para tests.
  static Future<Database> openInMemory() async {
    sqfliteFfiInit();
    // SQLite reutiliza la base `:memory:` entre aperturas, asi que sin este
    // borrado los datos de un test se filtran al siguiente.
    await databaseFactoryFfi.deleteDatabase(inMemoryDatabasePath);
    return databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: _configure,
        onCreate: _createSchema,
      ),
    );
  }

  /// SQLite ignora las llaves foraneas si no se activan explicitamente,
  /// y hay que hacerlo por conexion, no una sola vez.
  static Future<void> _configure(Database db) => db.execute('PRAGMA foreign_keys = ON');

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id            TEXT PRIMARY KEY,
        name          TEXT NOT NULL,
        email         TEXT NOT NULL COLLATE NOCASE UNIQUE,
        password_hash TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transfers (
        id                  TEXT PRIMARY KEY,
        source_user_id      TEXT NOT NULL REFERENCES users(id),
        destination_user_id TEXT NOT NULL REFERENCES users(id),
        amount_in_cents     INTEGER NOT NULL CHECK (amount_in_cents > 0),
        description         TEXT,
        created_at          INTEGER NOT NULL,
        CHECK (source_user_id <> destination_user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE session (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_transfers_created_at ON transfers(created_at DESC)');
  }
}
