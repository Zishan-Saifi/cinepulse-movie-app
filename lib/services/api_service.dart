import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class ApiService {
  // Apni 32-character TMDB API Key yahan paste karein:
  static const String _apiKey = '92ead79f873c564582766544bf65fff1';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // 1. Trending Movies laane ke liye (Pagination support ke saath)
  Future<List<Movie>> getTrendingMovies({int page = 1}) async {
    final url = Uri.parse('$_baseUrl/trending/movie/week?api_key=$_apiKey&page=$page');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'] ?? [];
      return results.map((m) => Movie.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load trending movies: ${response.statusCode}');
    }
  }

  // 2. Movie search karne ke liye
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];
    final url = Uri.parse('$_baseUrl/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(query)}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'] ?? [];
      return results.map((m) => Movie.fromJson(m)).toList();
    } else {
      throw Exception('Failed to search movies: ${response.statusCode}');
    }
  }
}