
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/movie.dart';

class MoviePage {
  final List<Movie> movies;
  final int page;
  final int totalPages;
  final int totalResults;

  const MoviePage({
    required this.movies,
    required this.page,
    required this.totalPages,
    required this.totalResults,
  });

  bool get hasMore => page < totalPages;
}

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    return 'http://10.0.2.2:8000';
  }

  static final http.Client _client = http.Client();

  static final Map<String, _CacheEntry> _cache = {};

  static final Map<String, Future<Map<String, dynamic>>> _inFlight = {};

  static const Duration _cacheDuration = Duration(minutes: 5);

  static void clearCache() {
    _cache.clear();
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final cacheKey = url.toString();

    final cached = _cache[cacheKey];

    if (cached != null &&
        DateTime.now().difference(cached.createdAt) < _cacheDuration) {
      return cached.data;
    }

    final pendingRequest = _inFlight[cacheKey];

    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _fetch(url);
    _inFlight[cacheKey] = request;

    try {
      final data = await request;

      _cache[cacheKey] = _CacheEntry(
        data: data,
        createdAt: DateTime.now(),
      );

      return data;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  static Future<Map<String, dynamic>> _fetch(Uri url) async {
    try {
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        throw const FormatException('Invalid API response format');
      }

      if (kDebugMode) {
        debugPrint('API FAILED: $url');
        debugPrint('STATUS: ${response.statusCode}');
        debugPrint('BODY: ${response.body}');
      }

      throw Exception('API error: ${response.statusCode}');
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('API TIMEOUT: $url');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('API ERROR: $url');
        debugPrint('$e');
      }
      rethrow;
    }
  }

  // Paginated movies with page metadata.
  static Future<MoviePage> _getMoviesPage(String path) async {
    final data = await _get(path);

    final results = data['results'] as List? ?? [];

    final movies = results
        .map(
          (item) => Movie.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();

    return MoviePage(
      movies: movies,
      page: (data['page'] as num?)?.toInt() ?? 1,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 1,
      totalResults: (data['total_results'] as num?)?.toInt() ?? movies.length,
    );
  }

  // Existing list method retained for other screens.
  static Future<List<Movie>> _getMovies(String path) async {
    final result = await _getMoviesPage(path);
    return result.movies;
  }

  // Paginated home sections.
  static Future<MoviePage> getTrendingPage({int page = 1}) {
    return _getMoviesPage('/movies/trending?page=$page');
  }

  static Future<MoviePage> getPopularPage({int page = 1}) {
    return _getMoviesPage('/movies/popular?page=$page');
  }

  static Future<MoviePage> getNowPlayingPage({int page = 1}) {
    return _getMoviesPage('/movies/now-playing?page=$page');
  }

  static Future<MoviePage> getUpcomingPage({int page = 1}) {
    return _getMoviesPage('/movies/upcoming?page=$page');
  }

  // Original methods retained for compatibility.
  static Future<List<Movie>> getTrending({int page = 1}) {
    return _getMovies('/movies/trending?page=$page');
  }

  static Future<List<Movie>> getPopular({int page = 1}) {
    return _getMovies('/movies/popular?page=$page');
  }

  static Future<List<Movie>> getNowPlaying({int page = 1}) {
    return _getMovies('/movies/now-playing?page=$page');
  }

  static Future<List<Movie>> getUpcoming({int page = 1}) {
    return _getMovies('/movies/upcoming?page=$page');
  }

  // Search with pagination.
  static Future<Map<String, dynamic>> searchMoviesPage(
      String query, {
        int page = 1,
      }) async {
    final encoded = Uri.encodeQueryComponent(query);

    final data = await _get(
      '/movies/search?q=$encoded&page=$page',
    );

    final results = data['results'] as List? ?? [];

    return {
      'total_pages': data['total_pages'] ?? 1,
      'movies': results
          .map(
            (item) => Movie.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList(),
    };
  }

  static Future<List<Movie>> searchMovies(
      String query, {
        int page = 1,
      }) {
    final encoded = Uri.encodeQueryComponent(query);

    return _getMovies(
      '/movies/search?q=$encoded&page=$page',
    );
  }

  static Future<Movie> getDetails(int id) async {
    final data = await _get('/movies/$id');
    return Movie.fromJson(data);
  }

  static Future<List<Movie>> getSimilar(int id) {
    return _getMovies('/movies/$id/similar');
  }

  static Future<List<Movie>> getRecommendations(int id) {
    return _getMovies('/movies/$id/recommendations');
  }

  static Future<List<Map<String, dynamic>>> getGenres() async {
    final data = await _get('/movies/genres');

    return List<Map<String, dynamic>>.from(
      data['genres'] ?? [],
    );
  }

  static Future<List<Movie>> getMoviesByGenre(
      int genreId, {
        int page = 1,
      }) {
    return _getMovies('/movies/genre/$genreId?page=$page');
  }

  static Future<MoviePage> getMoviesByGenrePage(
      int genreId, {
        int page = 1,
      }) {
    return _getMoviesPage('/movies/genre/$genreId?page=$page');
  }

  static Future<Map<String, dynamic>> getCredits(int id) {
    return _get('/movies/$id/credits');
  }

  static Future<Map<String, dynamic>> getTrailer(int id) {
    return _get('/movies/$id/trailer');
  }
}

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const _CacheEntry({
    required this.data,
    required this.createdAt,
  });
}
