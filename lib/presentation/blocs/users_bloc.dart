import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/usecases/create_user.dart';
import 'package:prueba_tecnica/domain/usecases/delete_user.dart';
import 'package:prueba_tecnica/domain/usecases/get_users.dart';
import 'package:prueba_tecnica/domain/usecases/update_user.dart';

sealed class UsersEvent {
  const UsersEvent();
}

class UsersRequested extends UsersEvent {
  const UsersRequested();
}

class UserSubmitted extends UsersEvent {
  final String? id;
  final String name;
  final String email;
  final String? password;

  const UserSubmitted({
    this.id,
    required this.name,
    required this.email,
    this.password,
  });

  bool get isNew => id == null;
}

class UserRemoved extends UsersEvent {
  final String id;
  const UserRemoved(this.id);
}

sealed class UsersState {
  const UsersState();
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersLoadFailed extends UsersState {
  final String message;
  const UsersLoadFailed(this.message);
}

class UsersReady extends UsersState {
  final List<User> users;
  final String? notice;
  final bool noticeIsError;

  const UsersReady(this.users, {this.notice, this.noticeIsError = false});
}

@injectable
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final GetUsers _getUsers;
  final CreateUser _createUser;
  final UpdateUser _updateUser;
  final DeleteUser _deleteUser;

  UsersBloc(
    this._getUsers,
    this._createUser,
    this._updateUser,
    this._deleteUser,
  ) : super(const UsersLoading()) {
    on<UsersRequested>((_, emit) async => emit(await _reload()));
    on<UserSubmitted>(_onSubmitted);
    on<UserRemoved>(_onRemoved);
  }

  Future<UsersState> _reload({String? notice, bool isError = false}) async {
    final result = await _getUsers();
    return switch (result) {
      Err(:final failure) => UsersLoadFailed(failure.message),
      Ok(:final value) => UsersReady(
        value,
        notice: notice,
        noticeIsError: isError,
      ),
    };
  }

  Future<void> _onSubmitted(
    UserSubmitted event,
    Emitter<UsersState> emit,
  ) async {
    final result = event.isNew
        ? await _createUser(
            name: event.name,
            email: event.email,
            password: event.password ?? '',
          )
        : await _updateUser(
            id: event.id!,
            name: event.name,
            email: event.email,
            newPassword: event.password,
          );

    switch (result) {
      case Err(:final failure):
        emit(await _reload(notice: failure.message, isError: true));
      case Ok():
        emit(
          await _reload(
            notice: event.isNew ? 'Usuario creado' : 'Cambios guardados',
          ),
        );
    }
  }

  Future<void> _onRemoved(UserRemoved event, Emitter<UsersState> emit) async {
    final result = await _deleteUser(event.id);
    switch (result) {
      case Err(:final failure):
        emit(await _reload(notice: failure.message, isError: true));
      case Ok():
        emit(await _reload(notice: 'Usuario eliminado'));
    }
  }
}
