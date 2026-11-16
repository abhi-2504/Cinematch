
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/movie_card.dart';

class DetailsScreen extends StatefulWidget {
  final Movie movie;

  const DetailsScreen({
    super.key,
    required this.movie,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Movie? details;

  List<Movie> recommendations = [];
  List<Movie> similar = [];
  List<String> cast = [];

  bool loading = true;
  String? trailerKey;
  bool showTrailer = false;

  YoutubePlayerController? trailerController;

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  // Load main movie details first.
  Future<void> loadDetails() async {
    try {
      final movieDetails =
      await ApiService.getDetails(widget.movie.id);

      if (!mounted) return;

      // Display movie immediately.
      setState(() {
        details = movieDetails;
        loading = false;
      });

      // Load remaining information in background.
      unawaited(loadRecommendations());
      unawaited(loadSimilar());
      unawaited(loadCredits());
      unawaited(loadTrailer());

    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load movie details: $error'),
        ),
      );
    }
  }

  // Load recommended movies separately.
  Future<void> loadRecommendations() async {
    try {
      final result =
      await ApiService.getRecommendations(widget.movie.id);

      if (!mounted) return;

      setState(() {
        recommendations = result;
      });
    } catch (e) {
      debugPrint('Recommendations loading failed: $e');
    }
  }

  // Load similar movies separately.
  Future<void> loadSimilar() async {
    try {
      final result =
      await ApiService.getSimilar(widget.movie.id);

      if (!mounted) return;

      setState(() {
        similar = result;
      });
    } catch (e) {
      debugPrint('Similar movies loading failed: $e');
    }
  }

  // Load cast information separately.
  Future<void> loadCredits() async {
    try {
      final creditData =
      await ApiService.getCredits(widget.movie.id);

      final castData = creditData['cast'] as List? ?? [];

      final castNames = castData
          .take(10)
          .map((person) => person['name'].toString())
          .toList();

      if (!mounted) return;

      setState(() {
        cast = castNames;
      });
    } catch (e) {
      debugPrint('Cast loading failed: $e');
    }
  }

  // Load trailer separately.
  Future<void> loadTrailer() async {
    try {
      final trailerData =
      await ApiService.getTrailer(widget.movie.id);

      if (!mounted) return;

      if (trailerData['available'] == true) {
        setState(() {
          trailerKey = trailerData['youtube_key'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Trailer loading failed: $e');
    }
  }

  void playTrailer() {
    if (trailerKey == null) return;

    trailerController?.close();

    trailerController = YoutubePlayerController.fromVideoId(
      videoId: trailerKey!,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );

    setState(() {
      showTrailer = true;
    });
  }

  Future<void> addToWatchlist() async {
    try {
      final added = await WatchlistService.instance.addMovie(
        widget.movie.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'Movie added to your watchlist'
                : 'Movie is already in your watchlist',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save movie: $e'),
        ),
      );
    }
  }

  Widget movieRow(String title, List<Movie> movies) {
    if (movies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 275,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (_, _) =>
            const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = movies[index];

              return MovieCard(
                movie: item,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsScreen(movie: item),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    trailerController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movie = details ?? widget.movie;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Details'),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        children: [
          if (movie.backdropUrl != null)
            Container(
              width: double.infinity,
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: showTrailer &&
                    trailerController != null
                    ? YoutubePlayer(
                  controller: trailerController!,
                  aspectRatio: 16 / 9,
                )
                    : Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: movie.backdropUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      placeholder: (context, url) {
                        return const Center(
                          child:
                          CircularProgressIndicator(),
                        );
                      },
                      errorWidget:
                          (context, url, error) {
                        return const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.white54,
                        );
                      },
                    ),
                    if (trailerKey != null)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: playTrailer,
                          icon: const Icon(
                            Icons.play_arrow,
                            size: 30,
                          ),
                          label: const Text(
                            'Watch Trailer',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.redAccent,
                            foregroundColor:
                            Colors.white,
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  '${movie.releaseYear}  •  TMDB rating: ${movie.rating.toStringAsFixed(1)}/10',
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: addToWatchlist,
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('Add to Watchlist'),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  movie.overview.isEmpty
                      ? 'No overview available.'
                      : movie.overview,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Cast',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  cast.isEmpty
                      ? 'Loading cast information...'
                      : cast.join(' • '),
                ),

                const SizedBox(height: 20),

                if (movie.imdbUrl != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: movie.imdbUrl!,
                        ),
                      );

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'IMDb link copied. Open it in your browser.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text(
                      'IMDb movie page link',
                    ),
                  ),
              ],
            ),
          ),

          movieRow(
            'Recommended Movies',
            recommendations,
          ),

          movieRow(
            'Similar Movies',
            similar,
          ),
        ],
      ),
    );
  }
}
