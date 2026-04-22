class ApiConstants {
  static const String apiBaseUrl = 'http://72.60.47.238:3000/api/';

//   Auth
  static const String loginEP = 'auth/login';
  static const String registerEP = 'auth/register';

//   Home
  static const String getAllBooksEP = '/books';
  static const String getAllBooksCategoriesEP = '/books/categories';

//   Dashboard
  static const String addBook = '/admin/books';

//   Book Details
  static const String getBookById = '/books/{id}';

//   favorites
  static const String favorite = '/books/favorites';
  static const String addToFavorite = '/books/favorite';

}
class ApiErrors {
  static const String badRequestError = "badRequestError";
  static const String noContent = "noContent";
  static const String forbiddenError = "forbiddenError";
  static const String unauthorizedError = "unauthorizedError";
  static const String notFoundError = "notFoundError";
  static const String conflictError = "conflictError";
  static const String internalServerError = "internalServerError";
  static const String unknownError = "unknownError";
  static const String timeoutError = "timeoutError";
  static const String defaultError = "defaultError";
  static const String cacheError = "cacheError";
  static const String noInternetError = "noInternetError";
  static const String loadingMessage = "loading_message";
  static const String retryAgainMessage = "retry_again_message";
  static const String ok = "Ok";
}