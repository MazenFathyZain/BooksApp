import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/constants.dart';
import '../helpers/shared_pref_helper.dart';

class DioFactory {
  /// private constructor as I don't want to allow creating an instance of this class
  DioFactory._();

  static Dio? dio;

  static Dio getDio() {
    Duration timeOut = const Duration(seconds: 30);

    if (dio == null) {
      dio = Dio();
      dio!
        ..options.connectTimeout = timeOut
        ..options.receiveTimeout = timeOut;
      addDioHeaders();
      addDioInterceptor();
      return dio!;
    } else {
      return dio!;
    }
  }

  static Future<void> addDioHeaders() async {
    final savedLocale = await SharedPrefHelper.getString(AppConstants.localeKey);
    final locale = savedLocale.isEmpty ? 'en' : savedLocale;

    dio?.options.headers = {
      'Accept': 'application/json',
      'x-lang': locale,
      'Authorization': 'Bearer ${await SharedPrefHelper.getSecuredString(AppConstants.userToken)}',
    };
  }

  static Future<void> setTokenIntoHeaderAfterLogin(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(AppConstants.localeKey) ?? 'en';

    dio?.options.headers = {
      'Accept': 'application/json',
      'x-lang': savedLocale,
      'Authorization': 'Bearer $token',
    };
  }

  static void addDioInterceptor() {
    dio?.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final savedLocale =
          await SharedPrefHelper.getString(AppConstants.localeKey);
          final locale = savedLocale.isEmpty ? 'en' : savedLocale;

          options.headers['Accept'] = 'application/json';
          options.headers['x-lang'] = locale;
          options.headers['Authorization'] =
          'Bearer ${await SharedPrefHelper.getSecuredString(AppConstants.userToken)}';

          return handler.next(options);
        },
      ),
    );

    dio?.interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        requestHeader: true,
        responseHeader: true,
      ),
    );
  }

}
