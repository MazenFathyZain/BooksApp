import 'package:book/features/home/data/models/books_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/networking/api_constants.dart';

part 'book_details_apis.g.dart';

@RestApi(baseUrl: ApiConstants.apiBaseUrl)
abstract class BookDetailsApis {
  factory BookDetailsApis(Dio dio, {String baseUrl}) = _BookDetailsApis;

  @GET(ApiConstants.getBookById)
  Future<BooksResponse> getBookDetails(
      @Path('id') String bookId,
      );
}
