class AddFavoriteRequest {
  final String bookId;

  AddFavoriteRequest({required this.bookId});

  Map<String, dynamic> toJson() => {
    "bookId": bookId,
  };
}
