import 'package:bloc/bloc.dart';
import 'package:book/features/auth/data/models/login_request_body.dart';
import 'package:book/features/auth/data/models/register_request_body.dart';
import 'package:book/features/auth/data/repos/auth_repo.dart';
import 'package:meta/meta.dart';

import '../../../core/helpers/constants.dart';
import '../../../core/helpers/shared_pref_helper.dart';
import '../../../core/networking/dio_factory.dart';
import '../data/models/auth_response_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo _repo;

  AuthCubit(this._repo) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    try {
      final response = await _repo.login(
        LoginRequestBody(email: email, password: password),
      );
      await saveUserToken(response.token, response.role);
      emit(AuthLoginSuccess(response));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register(
      String name,
      String email,
      String password,
      String role,
      ) async {
    emit(AuthLoading());

    try {
      final response = await _repo.register(
        RegisterRequestBody(
          name: name,
          email: email,
          password: password,
          role: role,
        ),
      );

      emit(AuthRegisterSuccess(response));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  Future<void> saveUserToken(String token, String role) async {
    await SharedPrefHelper.setSecuredString(AppConstants.userToken, token);
    await SharedPrefHelper.setSecuredString(AppConstants.userRole, role);
    DioFactory.setTokenIntoHeaderAfterLogin(token);
  }
}
