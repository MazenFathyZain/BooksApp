// import 'dart:io';
//
// import 'package:book/features/auth/data/models/auth_response_model.dart';
// import 'package:book/features/auth/data/models/register_request_body.dart';
// import 'package:dio/dio.dart';
//
// import 'package:retrofit/retrofit.dart';
//
//
// import '../../../../core/networking/api_constants.dart';
//
// part 'favorite_apis.g.dart';
//
// @RestApi(baseUrl: ApiConstants.apiBaseUrl)
// abstract class FavoriteApis {
//   factory FavoriteApis(Dio dio, {String baseUrl}) = _FavoriteApis;
//
//
//   @POST(ApiConstants.registerEP)
//   Future<AuthResponseModel> register(@Body() RegisterRequestBody requestBody);
//
// }