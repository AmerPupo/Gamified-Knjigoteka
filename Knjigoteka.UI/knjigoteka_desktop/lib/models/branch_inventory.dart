class BranchInventory {
  final int bookId;
  final int branchId;
  final String? branchName;
  final String? branchAddress;
  final String title;
  final String author;
  final String genreName;
  final String languageName;
  final double price;
  final bool supportsBorrowing;
  final int quantityForBorrow;
  final int quantityForSale;
  final String? photoEndpoint; // dodaj sliku

  BranchInventory({
    required this.bookId,
    required this.branchId,
    this.branchName,
    this.branchAddress,
    required this.title,
    required this.author,
    required this.genreName,
    required this.languageName,
    required this.price,
    required this.supportsBorrowing,
    required this.quantityForBorrow,
    required this.quantityForSale,
    this.photoEndpoint,
  });

  factory BranchInventory.fromJson(Map<String, dynamic> json) =>
      BranchInventory(
        bookId: json['bookId'],
        branchId: json['branchId'],
        branchName: json['branchName'],
        branchAddress: json['branchAdress'],
        title: json['title'],
        author: json['author'],
        genreName: json['genreName'],
        languageName: json['languageName'],
        price: (json['price'] as num).toDouble(),
        supportsBorrowing: json['supportsBorrowing'],
        quantityForBorrow: json['quantityForBorrow'],
        quantityForSale: json['quantityForSale'],
        photoEndpoint: json['photoEndpoint'],
      );
}
