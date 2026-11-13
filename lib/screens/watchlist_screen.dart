
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/movie_card.dart';
import 'details_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  List<Movie> movies = [];
  bool loading = true;
  int failedCount = 0;

  @override
  void initState() {
    super.initState();
    loadWatchlist();
  }

  Future<void> loadWatchlist() async {
    if (mounted) {
      setState(() {
        loading = true;
        failedCount = 0;
      });
    }

    debugPrint('WATCHLIST LOADING STARTED');

    try {
      final ids = await WatchlistService.instance.getSavedIds();

      // Debug: Saved movie IDs
      debugPrint('SAVED WATCHLIST IDS: $ids');
      debugPrint('TOTAL SAVED IDS: ${ids.length}');

      final results = <Movie>[];
      int failed = 0;

      for (final id in ids) {
        try {
          debugPrint('LOADING MOVIE ID: $id');

          final movie = await ApiService.getDetails(
            int.parse(id),
          );

          results.add(movie);

          debugPrint(
            'SUCCESSFULLY LOADED MOVIE: ${movie.id}',
          );
        } catch (e, stackTrace) {
          failed++;

          debugPrint('FAILED MOVIE ID: $id');
          debugPrint('ERROR: $e');
          debugPrint('STACK TRACE: $stackTrace');
        }
      }

      // Debug: Final loading results
      debugPrint('TOTAL MOVIES LOADED: ${results.length}');
      debugPrint('FAILED MOVIES: $failed');

      if (!mounted) return;

      setState(() {
        movies = results;
        failedCount = failed;
        loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('WATCHLIST LOADING ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> removeMovie(Movie movie) async {
    await WatchlistService.instance.removeMovie(movie.id);

    if (!mounted) return;

    setState(() {
      movies.removeWhere((item) => item.id == movie.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Movie removed from watchlist'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: WatchlistService.instance,
          builder: (context, child) {
            return Text(
              'My Watchlist (${WatchlistService.instance.count})',
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Watchlist',
            onPressed: loadWatchlist,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : movies.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 55,
            ),
            const SizedBox(height: 12),
            const Text('Your watchlist is empty'),

            if (failedCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$failedCount saved movie(s) could not be loaded.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: loadWatchlist,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      )
          : Column(
        children: [
          if (failedCount > 0)
            MaterialBanner(
              content: Text(
                '$failedCount saved movie(s) could not be loaded. '
                    'Their IDs are still saved. Check your backend and retry.',
              ),
              actions: [
                TextButton(
                  onPressed: loadWatchlist,
                  child: const Text('RETRY'),
                ),
              ],
            ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: movies.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.58,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
              ),
              itemBuilder: (context, index) {
                final movie = movies[index];

                return Column(
                  children: [
                    Expanded(
                      child: MovieCard(
                        movie: movie,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailsScreen(movie: movie),
                            ),
                          );
                        },
                      ),
                    ),

                    TextButton.icon(
                      onPressed: () => removeMovie(movie),
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      label: const Text('Remove'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
