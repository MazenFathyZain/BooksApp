// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_apis.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter

class _DashboardApis implements DashboardApis {
  _DashboardApis(this._dio, {this.baseUrl, this.errorLogger}) {
    baseUrl ??= 'http://72.60.47.238:3000/api/';
  }

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<AddBookResponse> addBook(
    String title,
    String author,
    String category,
    String description,
    File? image,
    File? pdf,
    File? word,
    File? audio,
    int partsCount,
    String subject,
    String language,
    List<String> otherNames,
    List<String> translators,
    String publisher,
    String publishingPlace,
    int publicationYear,
    String bookVersion,
    String century,
    String authorDoctrine,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final _data = FormData();
    _data.fields.add(MapEntry('title', title));
    _data.fields.add(MapEntry('author', author));
    _data.fields.add(MapEntry('category', category));
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
    _data.fields.add(MapEntry('partsCount', partsCount.toString()));
    _data.fields.add(MapEntry('subject', subject));
    _data.fields.add(MapEntry('language', language));
    otherNames.forEach((i) {
      _data.fields.add(MapEntry('otherNames', i));
    });
    translators.forEach((i) {
      _data.fields.add(MapEntry('translators', i));
    });
    _data.fields.add(MapEntry('publisher', publisher));
    _data.fields.add(MapEntry('publishingPlace', publishingPlace));
    _data.fields.add(MapEntry('publicationYear', publicationYear.toString()));
    _data.fields.add(MapEntry('bookVersion', bookVersion));
    _data.fields.add(MapEntry('century', century));
    _data.fields.add(MapEntry('authorDoctrine', authorDoctrine));
    final _options = _setStreamType<AddBookResponse>(
      Options(
            method: 'POST',
            headers: _headers,
            extra: _extra,
            contentType: 'multipart/form-data',
          )
          .compose(
            _dio.options,
            '/books/upload',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late AddBookResponse _value;
    try {
      _value = AddBookResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    return _value;
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
