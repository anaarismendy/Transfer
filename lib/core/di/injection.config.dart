// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:prueba_tecnica/core/di/database_module.dart' as _i646;
import 'package:prueba_tecnica/data/datasources/session_local_datasource.dart'
    as _i1024;
import 'package:prueba_tecnica/data/datasources/transfer_local_datasource.dart'
    as _i955;
import 'package:prueba_tecnica/data/datasources/user_local_datasource.dart'
    as _i104;
import 'package:prueba_tecnica/data/repositories/auth_repository_impl.dart'
    as _i399;
import 'package:prueba_tecnica/data/repositories/transfer_repository_impl.dart'
    as _i995;
import 'package:prueba_tecnica/data/repositories/user_repository_impl.dart'
    as _i477;
import 'package:prueba_tecnica/data/services/bcrypt_password_hasher.dart'
    as _i330;
import 'package:prueba_tecnica/domain/repositories/auth_repository.dart'
    as _i951;
import 'package:prueba_tecnica/domain/repositories/transfer_repository.dart'
    as _i299;
import 'package:prueba_tecnica/domain/repositories/user_repository.dart'
    as _i371;
import 'package:prueba_tecnica/domain/services/password_hasher.dart' as _i1050;
import 'package:prueba_tecnica/domain/usecases/seed_default_user.dart' as _i655;
import 'package:sqflite/sqflite.dart' as _i779;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    await gh.lazySingletonAsync<_i779.Database>(
      () => databaseModule.database,
      preResolve: true,
    );
    gh.lazySingleton<_i1050.PasswordHasher>(() => _i330.BcryptPasswordHasher());
    gh.lazySingleton<_i1024.SessionLocalDataSource>(
      () => _i1024.SessionLocalDataSource(gh<_i779.Database>()),
    );
    gh.lazySingleton<_i955.TransferLocalDataSource>(
      () => _i955.TransferLocalDataSource(gh<_i779.Database>()),
    );
    gh.lazySingleton<_i104.UserLocalDataSource>(
      () => _i104.UserLocalDataSource(gh<_i779.Database>()),
    );
    gh.lazySingleton<_i951.AuthRepository>(
      () => _i399.AuthRepositoryImpl(gh<_i1024.SessionLocalDataSource>()),
    );
    gh.lazySingleton<_i299.TransferRepository>(
      () => _i995.TransferRepositoryImpl(gh<_i955.TransferLocalDataSource>()),
    );
    gh.lazySingleton<_i371.UserRepository>(
      () => _i477.UserRepositoryImpl(gh<_i104.UserLocalDataSource>()),
    );
    gh.factory<_i655.SeedDefaultUser>(
      () => _i655.SeedDefaultUser(
        gh<_i371.UserRepository>(),
        gh<_i1050.PasswordHasher>(),
      ),
    );
    return this;
  }
}

class _$DatabaseModule extends _i646.DatabaseModule {}
