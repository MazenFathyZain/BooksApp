// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_details_apis.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter

class _BookDetailsApis implements BookDetailsApis {
  _BookDetailsApis(this._dio, {this.baseUrl, this.errorLogger}) {
    baseUrl ??= 'http://72.60.47.238:3000/api/';
  }

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<BooksResponse> getBookDetails(String bookId) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<BooksResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/books/${bookId}',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BooksResponse _value;
    try {
      _value = BooksResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    return _value;
  }

  @override
  Future<BooksResponse> updateBook(
    String bookId,
    String title,
    String author,
    String category,
    String? categoryId,
    String? subCategoryId,
    String description,
    File? image,
    File? pdf,
    File? word,
    File? audio,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = FormData();
    _data.fields.add(MapEntry('title', title));
    _data.fields.add(MapEntry('author', author));
    _data.fields.add(MapEntry('category', category));
    if (categoryId != null) {
      _data.fields.add(MapEntry('categoryId', categoryId));
    }
    if (subCategoryId != null) {
      _data.fields.add(MapEntry('subCategoryId', subCategoryId));
    }
    _data.fields.add(MapEntry('description', description));
    if (image != null) {
      _data.files.add(
        MapEntry(
          'image',
          MultipartFile.fromFileSync(
            image.path,
            filename: image.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }
    if (pdf != null) {
      _data.files.add(
        MapEntry(
          'pdf',
          MultipartFile.fromFileSync(
            pdf.path,
            filename: pdf.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }
    if (word != null) {
      _data.files.add(
        MapEntry(
          'word',
          MultipartFile.fromFileSync(
            word.path,
            filename: word.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }
    if (audio != null) {
      _data.files.add(
        MapEntry(
          'audio',
          MultipartFile.fromFileSync(
            audio.path,
            filename: audio.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }
    final _options = _setStreamType<BooksResponse>(
      Options(
            method: 'PUT',
            headers: _headers,
            extra: _extra,
            contentType: 'multipart/form-data',
          )
          .compose(
            _dio.options,
            '/books/${bookId}',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BooksResponse _value;
    try {
      _value = BooksResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    return _value;
  }

  @override
  Future<void> deleteBook(String bookId) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<void>(
      Options(method: 'DELETE', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/books/${bookId}',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    await _dio.fetch<void>(_options);
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
