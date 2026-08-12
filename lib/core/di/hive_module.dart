import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// Boxes de Hive registrados como singletons. `@preResolve` hace que
/// `configureDependencies()` espere a que se abran antes de arrancar la app.
///
/// Se usan boxes sin tipar (mapas) en vez de TypeAdapters generados porque
/// hive_ce_generator exige analyzer ^14 e injectable_generator esta en ^13:
/// no pueden coexistir. Los mappers en data/models cubren la traduccion.
@module
abstract class HiveModule {
  @preResolve
  @lazySingleton
  @Named('users')
  Future<Box> get usersBox => Hive.openBox('users');

  @preResolve
  @lazySingleton
  @Named('transfers')
  Future<Box> get transfersBox => Hive.openBox('transfers');

  @preResolve
  @lazySingleton
  @Named('session')
  Future<Box> get sessionBox => Hive.openBox('session');
}
