import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/datasources/app_database.dart';

/// Una sola conexion para toda la app. `@preResolve` hace que
/// `configureDependencies()` espere a que la base este abierta y migrada.
@module
abstract class DatabaseModule {
  @preResolve
  @lazySingleton
  Future<Database> get database => AppDatabase.open();
}
