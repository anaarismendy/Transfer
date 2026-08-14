import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prueba_tecnica/domain/opening_balance.dart';

class AppDatabase {
  static const _fileName = 'prueba_tecnica.db';
  static const _version = 2;

  static Future<Database> open() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    return openDatabase(
      p.join(await getDatabasesPath(), _fileName),
      version: _version,
      onConfigure: _configure,
      onCreate: _createSchema,
      onUpgrade: _upgrade,
    );
  }

  static Future<Database> openInMemory() async {
    sqfliteFfiInit();
    await databaseFactoryFfi.deleteDatabase(inMemoryDatabasePath);
    return databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: _configure,
        onCreate: _createSchema,
        onUpgrade: _upgrade,
      ),
    );
  }

  static Future<void> _configure(Database db) =>
      db.execute('PRAGMA foreign_keys = ON');

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id               TEXT PRIMARY KEY,
        name             TEXT NOT NULL,
        email            TEXT NOT NULL COLLATE NOCASE UNIQUE,
        password_hash    TEXT NOT NULL,
        balance_in_cents INTEGER NOT NULL DEFAULT 0
          CONSTRAINT balance_not_negative CHECK (balance_in_cents >= 0)
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

    await db.execute(
      'CREATE INDEX idx_transfers_created_at ON transfers(created_at DESC)',
    );
  }

  /// Se acumula, no se reescribe: cada version agrega su bloque y los viejos
  /// quedan para quien venga desde mas atras.
  ///
  /// ponytail: SQLite no sabe agregar un CHECK con ALTER TABLE, asi que en una
  /// base que ya existia la columna llega sin `balance_not_negative`. La regla
  /// igual se valida en el caso de uso. Para igualar los esquemas habria que
  /// recrear la tabla y copiar, que aca no vale la pena.
  static Future<void> _upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE users ADD COLUMN balance_in_cents INTEGER NOT NULL DEFAULT 0',
      );
      await recomputeBalances(db);
    }
  }

  /// Reconstruye los saldos desde el historial que ya estaba guardado: cupo de
  /// apertura mas lo recibido menos lo enviado. Sin esto, una base vieja
  /// quedaria con todos en el mismo saldo y contradiciendo sus movimientos.
  ///
  /// El MAX(0, ...) es por si alguien alcanzo a enviar mas que el cupo cuando
  /// nadie validaba fondos.
  static Future<void> recomputeBalances(DatabaseExecutor db) => db.execute('''
      UPDATE users SET balance_in_cents = MAX(0,
        $openingBalanceInCents
        + COALESCE((SELECT SUM(amount_in_cents) FROM transfers
                    WHERE destination_user_id = users.id), 0)
        - COALESCE((SELECT SUM(amount_in_cents) FROM transfers
                    WHERE source_user_id = users.id), 0)
      )
    ''');
}
