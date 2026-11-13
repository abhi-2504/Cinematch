
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/api_service.dart';
import '../widgets/movie_card.dart';
import 'details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();

  Timer? _debounce;

  List<Movie> movies = [];

  bool loading = false;
  String? error;

  int page = 1;
  int totalPages = 1;
  int _requestVersion = 0;

  String query = '';

  // Automatically search while typing.
  void onSearchChanged(String text) {
    _debounce?.cancel();

    final searchText = text.trim();

    // Invalidate previous API requests.
    _requestVersion++;

    setState(() {
      movies.clear();
      error = null;
      loading = false;
      page = 1;
      totalPages = 1;
      query = searchText;
    });

    if (searchText.isEmpty) return;

    // Wait until the user pauses typing.
    _debounce = Timer(
      const Duration(milliseconds: 400),
          () => search(),
    );
  }

  Future<void> search({bool nextPage = false}) async {
    final text = nextPage ? query : controller.text.trim();

    if (text.isEmpty || loading) return;

    if (nextPage && page >= totalPages) return;

    final targetPage = nextPage ? page + 1 : 1;
    final requestVersion = ++_requestVersion;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await ApiService.searchMoviesPage(
        text,
        page: targetPage,
      );

      // Ignore old responses.
      if (!mounted || requestVersion != _requestVersion) return;

      final newMovies = result['movies'] as List<Movie>;

      setState(() {
        totalPages = result['total_pages'] as int? ?? 1;

        if (nextPage) {
          movies.addAll(newMovies);
        } else {
          movies = newMovies;
        }

        page = targetPage;
        loading = false;
      });
    } catch (e) {
      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void clearSearch() {
    _debounce?.cancel();
    _requestVersion++;
    controller.clear();

    setState(() {
      movies.clear();
      error = null;
      loading = false;
      query = '';
      page = 1;
      totalPages = 1;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Movies'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search movies...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: clearSearch,
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          if (loading)
            const LinearProgressIndicator(),

          if (error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),

          if (!loading && error == null && query.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Search for your favourite movies'),
              ),
            ),

          if (!loading &&
              error == null &&
              query.isNotEmpty &&
              movies.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No movies found'),
              ),
            ),

          if (movies.isNotEmpty)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: movies.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.52,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final movie = movies[index];

                  return MovieCard(
                    movie: movie,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailsScreen(movie: movie),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          if (loading && movies.isEmpty)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),

          if (movies.isNotEmpty && page < totalPages)
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton(
                onPressed: loading
                    ? null
                    : () => search(nextPage: true),
                child: const Text('Load More'),
              ),
            ),
        ],
      ),
    );
  }
}
