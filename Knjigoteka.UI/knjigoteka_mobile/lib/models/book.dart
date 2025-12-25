import 'dart:typed_data';

class Book {
  final int id;
  final String title;
  final String author;
  final int genreId;
  final String genreName;
  final int languageId;
  final String languageName;
  final String isbn;
  final int year;
  final int centralStock;
  final int calculatedTotalQuantity;
  final String shortDescription;
  final double price;
  final bool hasImage;
  final String photoEndpoint;
  final double? averageRating;
  final Uint8List? bookImageBytes;
  final int reviewsCount;
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.genreId,
    required this.genreName,
    required this.languageId,
    required this.languageName,
    required this.isbn,
    required this.year,
    required this.centralStock,
    required this.calculatedTotalQuantity,
    required this.shortDescription,
    required this.price,
    required this.hasImage,
    required this.photoEndpoint,
    this.averageRating,
    this.bookImageBytes,
    this.reviewsCount = 0,
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'],
    title: json['title'],
    author: json['author'],
    genreId: json['genreId'],
    genreName: json['genreName'],
    languageId: json['languageId'],
    languageName: json['languageName'],
    isbn: json['isbn'],
    year: json['year'],
    centralStock: json['centralStock'],
    calculatedTotalQuantity: json['calculatedTotalQuantity'],
    shortDescription: json['shortDescription'],
    price: (json['price'] as num).toDouble(),
    hasImage: json['hasImage'],
    photoEndpoint: json['photoEndpoint'],
    averageRating: json['averageRating'] != null
        ? (json['averageRating'] as num).toDouble()
        : 0,
    bookImageBytes: json['bookImageBytes'] != null
        ? Uint8List.fromList(List<int>.from(json['bookImageBytes']))
        : null,
    reviewsCount: json['reviewsCount'] ?? 0,
  );
}

class BookInsert {
  final String title;
  final String author;
  final int genreId;
  final int languageId;
  final String isbn;
  final int year;
  final int centralStock;
  final String shortDescription;
  final double price;
  final List<int>? bookImage;

  BookInsert({
    required this.title,
    required this.author,
    required this.genreId,
    required this.languageId,
    required this.isbn,
    required this.year,
    required this.centralStock,
    required this.shortDescription,
    required this.price,
    this.bookImage,
  });

  Map<String, dynamic> toJson() => {
    "title": title,
    "author": author,
    "genreId": genreId,
    "languageId": languageId,
    "isbn": isbn,
    "year": year,
    "centralStock": centralStock,
    "shortDescription": shortDescription,
    "price": price,
    "bookImage": bookImage,
  };
}
