import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/datasources/app_database.dart';

@module
abstract class DatabaseModule {
  @preResolve
  @lazySingleton
  Future<Database> get database => AppDatabase.open();
}
