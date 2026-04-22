import 'package:book/features/auth/data/apis/auth_apis.dart';
import 'package:book/features/auth/data/models/auth_response_model.dart';
import 'package:book/features/auth/data/models/login_request_body.dart';
import 'package:book/features/auth/data/models/register_request_body.dart';

class AuthRepo{
  final AuthApis api;
  AuthRepo(this.api);


  Future<AuthResponseModel>login(LoginRequestBody body)async{
   return await api.login(body);
  }
  Future<AuthResponseModel> register(RegisterRequestBody body)async{
   return await api.register(body);
  }
}