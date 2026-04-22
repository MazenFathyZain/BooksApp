import 'package:book/features/favorite/data/apis/favorite_apis.dart';
import 'package:book/features/home/data/models/books_response.dart';

class FavoriteRepo{
  final FavoriteApis _api;
  FavoriteRepo(this._api);


  Future<List<BooksResponse>> getFavoriteBooks()async{
    return await _api.getFavoriteBooks();
  }
}