import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/usecases/get_current_user.dart';
import 'package:prueba_tecnica/domain/usecases/login.dart';
import 'package:prueba_tecnica/domain/usecases/logout.dart';

sealed class AuthEvent {
  const AuthEvent();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested(this.email, this.password);
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthInProgress extends AuthState {
  const AuthInProgress();
}

class AuthFailed extends AuthState {
  final String message;
  const AuthFailed(this.message);
}

class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
}

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Login _login;
  final Logout _logout;
  final GetCurrentUser _getCurrentUser;

  AuthBloc(this._login, this._logout, this._getCurrentUser) : super(const AuthUnknown()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final result = await _getCurrentUser();
    emit(result.fold(
      (_) => const Unauthenticated(),
      (user) => user == null ? const Unauthenticated() : Authenticated(user),
    ));
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthInProgress());
    final result = await _login(event.email, event.password);
    emit(result.fold(
      (failure) => AuthFailed(failure.message),
      (user) => Authenticated(user),
    ));
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await _logout();
    emit(const Unauthenticated());
  }
}
