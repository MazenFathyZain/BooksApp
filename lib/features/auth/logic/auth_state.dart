part of 'auth_cubit.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthLoginSuccess extends AuthState {
  final AuthResponseModel response;

  AuthLoginSuccess(this.response);
}

final class AuthRegisterSuccess extends AuthState {
  final AuthResponseModel response;

  AuthRegisterSuccess(this.response);
}

final class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
