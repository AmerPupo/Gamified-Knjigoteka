import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/review_response.dart';

class ReviewProvider with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  Future<List<ReviewResponse>> getMyReviews(String token) async {
    final resp = await http.get(
      Uri.parse("$_baseUrl/Review/mine"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body);
      return data.map((e) => ReviewResponse.fromJson(e)).toList();
    }
    throw Exception("Ne mogu dohvatiti recenzije.");
  }

  Future<ReviewResponse?> getBookReviewByMe(int bookId, String token) async {
    final resp = await http.get(
      Uri.parse("$_baseUrl/Review?BookId=$bookId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body);
      if (data.isNotEmpty) {
        return ReviewResponse.fromJson(data[0]);
      }
      return null;
    }
    return null;
  }

  Future<bool> submitReview({
    required int bookId,
    required int rating,
    required String token,
  }) async {
    print("Uslo u funkciju sa ratingom $rating");
    final resp = await http.post(
      Uri.parse("$_baseUrl/Review"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"bookId": bookId, "rating": rating}),
    );
    return resp.statusCode == 200 || resp.statusCode == 201;
  }
}
