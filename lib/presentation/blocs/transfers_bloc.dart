import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/usecases/create_transfer.dart';
import 'package:prueba_tecnica/domain/usecases/get_transfers.dart';
import 'package:prueba_tecnica/domain/usecases/get_users.dart';

sealed class TransfersEvent {
  const TransfersEvent();
}

class TransfersRequested extends TransfersEvent {
  const TransfersRequested();
}

class TransferSubmitted extends TransfersEvent {
  final String sourceUserId;
  final String destinationUserId;
  final int amountInCents;
  final String? description;

  const TransferSubmitted({
    required this.sourceUserId,
    required this.destinationUserId,
    required this.amountInCents,
    this.description,
  });
}

sealed class TransfersState {
  const TransfersState();
}

class TransfersLoading extends TransfersState {
  const TransfersLoading();
}

class TransfersLoadFailed extends TransfersState {
  final String message;
  const TransfersLoadFailed(this.message);
}

class TransfersReady extends TransfersState {
  final List<User> users;
  final List<Transfer> transfers;
  final String? error;
  final Transfer? created;

  const TransfersReady({
    required this.users,
    required this.transfers,
    this.error,
    this.created,
  });

  User? userById(String id) {
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  String nameOf(String id) => userById(id)?.name ?? 'Usuario eliminado';
}

@injectable
class TransfersBloc extends Bloc<TransfersEvent, TransfersState> {
  final GetUsers _getUsers;
  final GetTransfers _getTransfers;
  final CreateTransfer _createTransfer;

  TransfersBloc(this._getUsers, this._getTransfers, this._createTransfer)
    : super(const TransfersLoading()) {
    on<TransfersRequested>((_, emit) async => emit(await _reload()));
    on<TransferSubmitted>(_onSubmitted);
  }

  Future<TransfersState> _reload({String? error, Transfer? created}) async {
    final usersResult = await _getUsers();
    if (usersResult case Err(:final failure)) {
      return TransfersLoadFailed(failure.message);
    }

    final transfersResult = await _getTransfers();
    if (transfersResult case Err(:final failure)) {
      return TransfersLoadFailed(failure.message);
    }

    return TransfersReady(
      users: (usersResult as Ok<List<User>>).value,
      transfers: (transfersResult as Ok<List<Transfer>>).value,
      error: error,
      created: created,
    );
  }

  Future<void> _onSubmitted(
    TransferSubmitted event,
    Emitter<TransfersState> emit,
  ) async {
    final result = await _createTransfer(
      sourceUserId: event.sourceUserId,
      destinationUserId: event.destinationUserId,
      amountInCents: event.amountInCents,
      description: event.description,
    );

    switch (result) {
      case Err(:final failure):
        emit(await _reload(error: failure.message));
      case Ok(:final value):
        emit(await _reload(created: value));
    }
  }
}
