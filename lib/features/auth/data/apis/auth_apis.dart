import 'dart:io';

import 'package:book/features/auth/data/models/auth_response_model.dart';
import 'package:book/features/auth/data/models/register_request_body.dart';
import 'package:dio/dio.dart';

import 'package:retrofit/retrofit.dart';


import '../../../../core/networking/api_constants.dart';
import '../models/login_request_body.dart';

part 'auth_apis.g.dart';

@RestApi(baseUrl: ApiConstants.apiBaseUrl)
abstract class AuthApis {
  factory AuthApis(Dio dio, {String baseUrl}) = _AuthApis;

  @POST(ApiConstants.loginEP)
  Future<AuthResponseModel> login(@Body() LoginRequestBody requestBody);

  @POST(ApiConstants.registerEP)
  Future<AuthResponseModel> register(@Body() RegisterRequestBody requestBody);

}