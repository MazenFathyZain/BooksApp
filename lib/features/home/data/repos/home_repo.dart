import 'package:book/features/home/data/apis/home_apis.dart';
import 'package:book/features/home/data/models/add_favorite_request.dart';
import 'package:book/features/home/data/models/books_response.dart';

class HomeRepo{
final HomeApis _api;
HomeRepo(this._api);

Future<List<BooksResponse>> getAllBooks(String? search,String? category)async{
  return await _api.getBooks(search: search, category: category);
}

Future<List<String>> getAllBooksCategories()async{
  return await _api.getAllBooksCategories();

}
Future<void> addToFavorite(AddFavoriteRequest body)async{
  return await _api.addToFavorite(body);
}
}