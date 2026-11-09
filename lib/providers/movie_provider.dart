import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../services/api_service.dart';

class MovieProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Movie> _movies = [];
  List<Movie> _favorites = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;

  List<Movie> get movies => _movies;
  List<Movie> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  MovieProvider() {
    fetchTrendingMovies();
    loadFavorites();
  }

  // 1. Trending Movies fetch karna
  Future<void> fetchTrendingMovies({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _movies = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newMovies = await _apiService.getTrendingMovies(page: _currentPage);
      _movies = newMovies;
    } catch (e) {
      _errorMessage = 'Internet connection ya API me issue hai. Dobara koshish karein.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Infinite Scroll (Next page load karna)
  Future<void> loadMoreMovies() async {
    if (_isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final moreMovies = await _apiService.getTrendingMovies(page: _currentPage);
      _movies.addAll(moreMovies);
    } catch (e) {
      _currentPage--; // Fail hone par page wapas peeche
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // 3. Check karna ki movie favorite hai ya nahi
  bool isFavorite(int movieId) {
    return _favorites.any((m) => m.id == movieId);
  }

  // 4. Favorite Toggle (Add / Remove) + Local Storage Save
  Future<void> toggleFavorite(Movie movie) async {
    final exists = isFavorite(movie.id);
    if (exists) {
      _favorites.removeWhere((m) => m.id == movie.id);
    } else {
      _favorites.add(movie);
    }
    notifyListeners();
    await _saveFavoritesToStorage();
  }

  // 5. Phone memory me save karna (shared_preferences)
  Future<void> _saveFavoritesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList = _favorites.map((m) => json.encode(m.toJson())).toList();
    await prefs.setStringList('favorite_movies', encodedList);
  }

  // 6. Phone memory se saved favorites nikalna
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedList = prefs.getStringList('favorite_movies');
    if (savedList != null) {
      _favorites = savedList.map((item) => Movie.fromJson(json.decode(item))).toList();
      notifyListeners();
    }
  }
}