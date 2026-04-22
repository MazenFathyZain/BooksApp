import 'package:book/features/bookDetails/data/apis/book_details_apis.dart';
import 'package:book/features/home/data/models/books_response.dart';

class BookDetailsRepo {
  final BookDetailsApis _apis;
  BookDetailsRepo(this._apis);

  Future<BooksResponse> getBookById(String id) async {
    return await _apis.getBookDetails(id);
  }
}
