import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'api_error_model.dart';

// TODO: wallahy I will refactor this .. Omar Ahmed
enum DataSource {
  NO_CONTENT,
  BAD_REQUEST,
  FORBIDDEN,
  UNAUTORISED,
  NOT_FOUND,
  INTERNAL_SERVER_ERROR,
  CONNECT_TIMEOUT,
  CANCEL,
  RECIEVE_TIMEOUT,
  SEND_TIMEOUT,
  CACHE_ERROR,
  NO_INTERNET_CONNECTION,
  // API_LOGIC_ERROR,
  DEFAULT,
}

class ResponseCode {
  static const int SUCCESS = 200; // success with data
  static const int NO_CONTENT = 201; // success with no data (no content)
  static const int BAD_REQUEST = 400; // failure, API rejected request
  static const int UNAUTORISED = 401; // failure, user is not authorised
  static const int FORBIDDEN = 403; //  failure, API rejected request
  static const int INTERNAL_SERVER_ERROR = 500; // failure, crash in server side
  static const int NOT_FOUND = 404; // failure, not found
  static const int API_LOGIC_ERROR = 422; // API , lOGIC ERROR

  // local status code
  static const int CONNECT_TIMEOUT = -1;
  static const int CANCEL = -2;
  static const int RECIEVE_TIMEOUT = -3;
  static const int SEND_TIMEOUT = -4;
  static const int CACHE_ERROR = -5;
  static const int NO_INTERNET_CONNECTION = -6;
  static const int DEFAULT = -7;
}

class ResponseMessage {
  static const String NO_CONTENT =
      ApiErrors.noContent; // success with no data (no content)
  static const String BAD_REQUEST =
      ApiErrors.badRequestError; // failure, API rejected request
  static const String UNAUTORISED =
      ApiErrors.unauthorizedError; // failure, user is not authorised
  static const String FORBIDDEN =
      ApiErrors.forbiddenError; //  failure, API rejected request
  static const String INTERNAL_SERVER_ERROR =
      ApiErrors.internalServerError; // failure, crash in server side
  static const String NOT_FOUND =
      ApiErrors.notFoundError; // failure, crash in server side

  // local status code
  static String CONNECT_TIMEOUT = ApiErrors.timeoutError;
  static String CANCEL = ApiErrors.defaultError;
  static String RECIEVE_TIMEOUT = ApiErrors.timeoutError;
  static String SEND_TIMEOUT = ApiErrors.timeoutError;
  static String CACHE_ERROR = ApiErrors.cacheError;
  static String NO_INTERNET_CONNECTION = ApiErrors.noInternetError;
  static String DEFAULT = ApiErrors.defaultError;
}

extension DataSourceExtension on DataSource {
  ApiErrorModel getFailure() {
    switch (this) {
      case DataSource.NO_CONTENT:
        return ApiErrorModel(
          code: ResponseCode.NO_CONTENT,
          message: ResponseMessage.NO_CONTENT,
        );
      case DataSource.BAD_REQUEST:
        return ApiErrorModel(
          code: ResponseCode.BAD_REQUEST,
          message: ResponseMessage.BAD_REQUEST,
        );
      case DataSource.FORBIDDEN:
        return ApiErrorModel(
          code: ResponseCode.FORBIDDEN,
          message: ResponseMessage.FORBIDDEN,
        );
      case DataSource.UNAUTORISED:
        return ApiErrorModel(
          code: ResponseCode.UNAUTORISED,
          message: ResponseMessage.UNAUTORISED,
        );
      case DataSource.NOT_FOUND:
        return ApiErrorModel(
          code: ResponseCode.NOT_FOUND,
          message: ResponseMessage.NOT_FOUND,
        );
      case DataSource.INTERNAL_SERVER_ERROR:
        return ApiErrorModel(
          code: ResponseCode.INTERNAL_SERVER_ERROR,
          message: ResponseMessage.INTERNAL_SERVER_ERROR,
        );
      case DataSource.CONNECT_TIMEOUT:
        return ApiErrorModel(
          code: ResponseCode.CONNECT_TIMEOUT,
          message: ResponseMessage.CONNECT_TIMEOUT,
        );
      case DataSource.CANCEL:
        return ApiErrorModel(
          code: ResponseCode.CANCEL,
          message: ResponseMessage.CANCEL,
        );
      case DataSource.RECIEVE_TIMEOUT:
        return ApiErrorModel(
          code: ResponseCode.RECIEVE_TIMEOUT,
          message: ResponseMessage.RECIEVE_TIMEOUT,
        );
      case DataSource.SEND_TIMEOUT:
        return ApiErrorModel(
          code: ResponseCode.SEND_TIMEOUT,
          message: ResponseMessage.SEND_TIMEOUT,
        );
      case DataSource.CACHE_ERROR:
        return ApiErrorModel(
          code: ResponseCode.CACHE_ERROR,
          message: ResponseMessage.CACHE_ERROR,
        );
      case DataSource.NO_INTERNET_CONNECTION:
        return ApiErrorModel(
          code: ResponseCode.NO_INTERNET_CONNECTION,
          message: ResponseMessage.NO_INTERNET_CONNECTION,
        );
      case DataSource.DEFAULT:
        return ApiErrorModel(
          code: ResponseCode.DEFAULT,
          message: ResponseMessage.DEFAULT,
        );
    }
  }
}

class ErrorHandler implements Exception {
  late ApiErrorModel apiErrorModel;

  ErrorHandler.handle(dynamic error) {
    if (error is DioException) {
      // dio error so its an error from response of the API or from dio itself
      apiErrorModel = _handleError(error);
    } else {
      // default error
      apiErrorModel = DataSource.DEFAULT.getFailure();
    }
  }
}

ApiErrorModel _handleError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return DataSource.CONNECT_TIMEOUT.getFailure();
    case DioExceptionType.sendTimeout:
      return DataSource.SEND_TIMEOUT.getFailure();
    case DioExceptionType.receiveTimeout:
      return DataSource.RECIEVE_TIMEOUT.getFailure();
    case DioExceptionType.badResponse:
      if (error.response != null &&
          error.response?.statusCode != null &&
          error.response?.statusMessage != null) {
        return ApiErrorModel.fromJson(error.response!.data);
      } else {
        return DataSource.DEFAULT.getFailure();
      }
    case DioExceptionType.unknown:
      if (error.response != null &&
          error.response?.statusCode != null &&
          error.response?.statusMessage != null) {
        return ApiErrorModel.fromJson(error.response!.data);
      } else {
        return DataSource.DEFAULT.getFailure();
      }
    case DioExceptionType.cancel:
      return DataSource.CANCEL.getFailure();
    case DioExceptionType.connectionError:
      return DataSource.DEFAULT.getFailure();
    case DioExceptionType.badCertificate:
      return DataSource.DEFAULT.getFailure();
    case DioExceptionType.badResponse:
      return DataSource.DEFAULT.getFailure();
  }
}

class ApiErrorFormatter {
  ApiErrorFormatter._();

  static String getMessage(Object error) {
    if (error is ErrorHandler) {
      return _cleanMessage(error.apiErrorModel.message) ??
          _messageForCode(error.apiErrorModel.code);
    }

    if (error is DioException) {
      return _messageForDioException(error);
    }

    final message = _cleanMessage(error.toString());
    return message ?? 'Something went wrong. Please try again.';
  }

  static String _messageForDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request took too long. Please check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network and try again.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Could not verify the server connection.';
      case DioExceptionType.badResponse:
        return _messageForResponse(error.response);
      case DioExceptionType.unknown:
        if (error.response != null) {
          return _messageForResponse(error.response);
        }
        return 'Could not connect to the server. Please try again.';
    }
  }

  static String _messageForResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final serverMessage = _extractServerMessage(response?.data);
    if (serverMessage != null) {
      return serverMessage;
    }

    return _messageForCode(statusCode);
  }

  static String _messageForCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Some information is missing or invalid. Please check and try again.';
      case 401:
        return 'Please log in again to continue.';
      case 403:
        return 'You do not have permission to do this action.';
      case 404:
        return 'The requested item was not found.';
      case 409:
        return 'This item already exists or conflicts with existing data.';
      case 422:
        return 'Please check the entered information and try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'The server is currently unavailable. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String? _extractServerMessage(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is String) {
      return _cleanMessage(data);
    }

    if (data is List) {
      final messages =
          data
              .map(_extractServerMessage)
              .whereType<String>()
              .where((message) => message.trim().isNotEmpty)
              .toList();
      return messages.isEmpty ? null : messages.join('\n');
    }

    if (data is Map) {
      for (final key in const [
        'message',
        'error',
        'errors',
        'detail',
        'details',
      ]) {
        if (data.containsKey(key)) {
          final message = _extractServerMessage(data[key]);
          if (message != null) {
            return message;
          }
        }
      }
    }

    return null;
  }

  static String? _cleanMessage(String? message) {
    if (message == null) {
      return null;
    }

    final trimmed =
        message
            .replaceFirst('DioException [bad response]:', '')
            .replaceFirst('DioException:', '')
            .replaceFirst('Exception:', '')
            .trim();

    if (trimmed.isEmpty || trimmed == 'null') {
      return null;
    }

    if (trimmed.contains('Http status error') ||
        trimmed.contains(
          'This exception was thrown because the response has a status code',
        )) {
      return null;
    }

    return trimmed;
  }
}

class ApiInternalStatus {
  static const int SUCCESS = 0;
  static const int FAILURE = 1;
}
