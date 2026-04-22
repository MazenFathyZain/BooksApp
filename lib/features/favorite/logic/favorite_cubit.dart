import 'package:bloc/bloc.dart';
import 'package:book/features/favorite/data/repos/favorite_repo.dart';
import 'package:book/features/home/data/models/books_response.dart';
import 'package:meta/meta.dart';

part 'favorite_state.dart';

class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoriteRepo _repo;
  FavoriteCubit(this._repo) : super(FavoriteInitial());

  getFavoriteBooks()async{
    emit(FavoriteLoading());
    try{
      final response = await _repo.getFavoriteBooks();
      emit(FavoriteSuccess(response));
    }catch(e){
      emit(FavoriteFailed(e.toString()));
    }
  }
}
