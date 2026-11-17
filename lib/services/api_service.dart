
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
      return 'https://cinematch-2k7a.onrender.com';
    }
    return 'http://10.0.2.2:8000';
  }

  static final http.Client _client = http.Client();

  static final Map<String, _CacheEntry> _cache = {};
  static final Map<String, Future<Map<String, dynamic>>> _inFlight = {};

  static const Duration _cacheDuration = Duration(minutes: 5);
  static const Duration _requestTimeout = Duration(seconds: 35);
  static const int _maxAttempts = 2;

  static void clearCache() {
    _cache.clear();
  }

  static void clearExpiredCache() {
    final now = DateTime.now();

    _cache.removeWhere(
          (_, entry) => now.difference(entry.createdAt) >= _cacheDuration,
    );
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final key = uri.toString();

    clearExpiredCache();

    final cached = _cache[key];
    if (cached != null) {
      return cached.data;
    }

    final existingRequest = _inFlight[key];
    if (existingRequest != null) {
      return existingRequest;
    }

    final request = _fetchWithRetry(uri);
    _inFlight[key] = request;

    try {
      final data = await request;

      _cache[key] = _CacheEntry(
        data: data,
        createdAt: DateTime.now(),
      );

      return data;
    } finally {
      _inFlight.remove(key);
    }
  }

  static Future<Map<String, dynamic>> _fetchWithRetry(Uri uri) async {
    Object? lastError;

    for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _client
            .get(uri)
            .timeout(_requestTimeout);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            return decoded;
          }

          throw const FormatException('Invalid API response format');
        }

        // Retry only temporary server errors.
        if (response.statusCode >= 500 &&
            attempt < _maxAttempts) {
          await Future.delayed(
            Duration(milliseconds: 500 * attempt),
          );
          continue;
        }

        throw Exception(
          'API error ${response.statusCode}: ${response.body}',
        );
      } on TimeoutException catch (e) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('API timeout, attempt $attempt: $uri');
        }
      } on http.ClientException catch (e) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('API connection error, attempt $attempt: $e');
        }
      } catch (e) {
        // Do not retry invalid JSON or ordinary 4xx errors.
        if (kDebugMode) {
          debugPrint('API request failed: $uri\n$e');
        }
        rethrow;
      }

      if (attempt < _maxAttempts) {
        await Future.delayed(
          Duration(milliseconds: 500 * attempt),
        );
      }
    }

    throw Exception(
      'Unable to connect to CineMatch server. Please try again. '
          'Details: $lastError',
    );
  }

  static Future<MoviePage> _getMoviesPage(String path) async {
    final data = await _get(path);
    final results = data['results'] as List? ?? [];

    final movies = results
        .whereType<Map<String, dynamic>>()
        .map((item) => Movie.fromJson(item))
        .toList();

    return MoviePage(
      movies: movies,
      page: (data['page'] as num?)?.toInt() ?? 1,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 1,
      totalResults:
      (data['total_results'] as num?)?.toInt() ?? movies.length,
    );
  }

  static Future<List<Movie>> _getMovies(String path) async {
    return (await _getMoviesPage(path)).movies;
  }

  static Future<MoviePage> getTrendingPage({int page = 1}) =>
      _getMoviesPage('/movies/trending?page=$page');

  static Future<MoviePage> getPopularPage({int page = 1}) =>
      _getMoviesPage('/movies/popular?page=$page');

  static Future<MoviePage> getNowPlayingPage({int page = 1}) =>
      _getMoviesPage('/movies/now-playing?page=$page');

  static Future<MoviePage> getUpcomingPage({int page = 1}) =>
      _getMoviesPage('/movies/upcoming?page=$page');

  static Future<List<Movie>> getTrending({int page = 1}) =>
      _getMovies('/movies/trending?page=$page');

  static Future<List<Movie>> getPopular({int page = 1}) =>
      _getMovies('/movies/popular?page=$page');

  static Future<List<Movie>> getNowPlaying({int page = 1}) =>
      _getMovies('/movies/now-playing?page=$page');

  static Future<List<Movie>> getUpcoming({int page = 1}) =>
      _getMovies('/movies/upcoming?page=$page');

  static Future<Map<String, dynamic>> searchMoviesPage(
      String query, {
        int page = 1,
      }) async {
    final uri = Uri(
      path: '/movies/search',
      queryParameters: {'q': query, 'page': '$page'},
    );

    final data = await _get(uri.toString());
    final results = data['results'] as List? ?? [];

    return {
      'total_pages': data['total_pages'] ?? 1,
      'movies': results
          .whereType<Map<String, dynamic>>()
          .map((item) => Movie.fromJson(item))
          .toList(),
    };
  }

  static Future<List<Movie>> searchMovies(
      String query, {
        int page = 1,
      }) async {
    final uri = Uri(
      path: '/movies/search',
      queryParameters: {'q': query, 'page': '$page'},
    );
    return _getMovies(uri.toString());
  }

  static Future<Movie> getDetails(int id) async {
    final data = await _get('/movies/$id');
    return Movie.fromJson(data);
  }

  static Future<List<Movie>> getSimilar(int id) =>
      _getMovies('/movies/$id/similar');

  static Future<List<Movie>> getRecommendations(int id) =>
      _getMovies('/movies/$id/recommendations');

  static Future<List<Map<String, dynamic>>> getGenres() async {
    final data = await _get('/movies/genres');
    return List<Map<String, dynamic>>.from(data['genres'] ?? []);
  }

  static Future<List<Movie>> getMoviesByGenre(
      int genreId, {
        int page = 1,
      }) =>
      _getMovies('/movies/genre/$genreId?page=$page');

  static Future<MoviePage> getMoviesByGenrePage(
      int genreId, {
        int page = 1,
      }) =>
      _getMoviesPage('/movies/genre/$genreId?page=$page');

  static Future<Map<String, dynamic>> getCredits(int id) =>
      _get('/movies/$id/credits');

  static Future<Map<String, dynamic>> getTrailer(int id) =>
      _get('/movies/$id/trailer');
}

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const _CacheEntry({
    required this.data,
    required this.createdAt,
  });
}
