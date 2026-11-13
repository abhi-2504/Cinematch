
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/movie_section.dart';
import 'details_screen.dart';
import 'watchlist_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> genres = [];

  bool _genresLoading = true;
  String? _genreError;

  final ScrollController _homeScrollController =
  ScrollController();

  final FocusNode _homeFocusNode = FocusNode();

  final GlobalKey<MovieSectionState> _trendingKey =
  GlobalKey<MovieSectionState>();

  final GlobalKey<MovieSectionState> _popularKey =
  GlobalKey<MovieSectionState>();

  final GlobalKey<MovieSectionState> _nowPlayingKey =
  GlobalKey<MovieSectionState>();

  final GlobalKey<MovieSectionState> _upcomingKey =
  GlobalKey<MovieSectionState>();

  @override
  void initState() {
    super.initState();

    loadHome();
    WatchlistService.instance.loadCount();
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _homeFocusNode.dispose();
    super.dispose();
  }

  // Only load genres initially.
  // Movie sections load their own first pages when built.
  Future<void> loadHome() async {
    if (mounted) {
      setState(() {
        _genresLoading = true;
        _genreError = null;
      });
    }

    try {
      final genreResults = await ApiService.getGenres();

      if (!mounted) return;

      setState(() {
        genres = genreResults;
        _genresLoading = false;
        _genreError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _genresLoading = false;
        _genreError = e.toString();
      });

      debugPrint('Genres loading failed: $e');
    }
  }

  // Refresh only sections which are currently mounted.
  // Other sections will load their first page when the user reaches them.
  Future<void> refreshHome() async {
    ApiService.clearCache();

    await loadHome();

    await Future.wait([
      _trendingKey.currentState?.refresh() ??
          Future<void>.value(),
      _popularKey.currentState?.refresh() ??
          Future<void>.value(),
      _nowPlayingKey.currentState?.refresh() ??
          Future<void>.value(),
      _upcomingKey.currentState?.refresh() ??
          Future<void>.value(),
    ]);
  }

  // Keyboard vertical scrolling.
  KeyEventResult handleHomeKeyboard(
      FocusNode node,
      KeyEvent event,
      ) {
    if (event is! KeyDownEvent ||
        !_homeScrollController.hasClients) {
      return KeyEventResult.ignored;
    }

    const amount = 250.0;

    double? target;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      target = _homeScrollController.offset + amount;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      target = _homeScrollController.offset - amount;
    }

    if (target == null) {
      return KeyEventResult.ignored;
    }

    final position = _homeScrollController.position;

    target = target.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    _homeScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );

    return KeyEventResult.handled;
  }

  // Open movie details.
  void openMovie(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(movie: movie),
      ),
    );
  }

  // Smart search suggestions.
  Future<Iterable<Movie>> getSuggestions(String input) async {
    final query = input.trim();

    if (query.isEmpty) {
      return [];
    }

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    try {
      final result = await ApiService.searchMoviesPage(
        query,
        page: 1,
      );

      final suggestions = result['movies'] as List<Movie>;

      return suggestions.take(6);
    } catch (e) {
      debugPrint('Search suggestions error: $e');
      return [];
    }
  }

  Widget buildSmartSearch(double screenWidth) {
    return Autocomplete<Movie>(
      displayStringForOption: (movie) => movie.title,

      optionsBuilder: (textEditingValue) {
        return getSuggestions(textEditingValue.text);
      },

      onSelected: openMovie,

      optionsViewBuilder: (context, onSelected, options) {
        final width = screenWidth > 700 ? 420.0 : 230.0;

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 12,
            color: const Color(0xFF202027),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: width,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final movie = options.elementAt(index);

                  return InkWell(
                    onTap: () => onSelected(movie),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Colors.white54,
                            size: 19,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.north_west,
                            color: Colors.white38,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },

      fieldViewBuilder: (
          context,
          textController,
          focusNode,
          onFieldSubmitted,
          ) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search movies, actors...',
            hintStyle: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Colors.white70,
            ),
            suffixIcon: textController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white70,
              ),
              onPressed: () {
                textController.clear();
                focusNode.requestFocus();
              },
            )
                : null,
            filled: true,
            fillColor: const Color(0xFF25252D),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1,
              ),
            ),
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  Widget buildCategorySection() {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Browse Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_genresLoading)
              const SizedBox(
                height: 35,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            else if (_genreError != null)
              TextButton.icon(
                onPressed: loadHome,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry categories'),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: genres.map((genre) {
                  final genreId = genre['id'] as int;
                  final genreName = genre['name'] as String;

                  return ActionChip(
                    label: Text(genreName),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryScreen(
                            genreId: genreId,
                            genreName: genreName,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildMovieSection(int index) {
    switch (index) {
      case 1:
        return RepaintBoundary(
          child: MovieSection(
            key: _trendingKey,
            title: 'Trending This Week',
            loadPage: (page) {
              return ApiService.getTrendingPage(page: page);
            },
            onMovieTap: openMovie,
          ),
        );

      case 2:
        return RepaintBoundary(
          child: MovieSection(
            key: _popularKey,
            title: 'Popular Movies',
            loadPage: (page) {
              return ApiService.getPopularPage(page: page);
            },
            onMovieTap: openMovie,
          ),
        );

      case 3:
        return RepaintBoundary(
          child: MovieSection(
            key: _nowPlayingKey,
            title: 'Now Playing',
            loadPage: (page) {
              return ApiService.getNowPlayingPage(page: page);
            },
            onMovieTap: openMovie,
          ),
        );

      case 4:
        return RepaintBoundary(
          child: MovieSection(
            key: _upcomingKey,
            title: 'Upcoming Movies',
            loadPage: (page) {
              return ApiService.getUpcomingPage(page: page);
            },
            onMovieTap: openMovie,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/images/cinematch_icon.jpg',
              width: 45,
              height: 45,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 5),
            const Text(
              'CineMatch',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildSmartSearch(screenWidth),
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: WatchlistService.instance,
            builder: (context, child) {
              final count = WatchlistService.instance.count;

              return IconButton(
                tooltip: 'Watchlist ($count)',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WatchlistScreen(),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.bookmark_outline,
                      size: 27,
                    ),
                    if (count > 0)
                      Positioned(
                        right: -9,
                        top: -7,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 19,
                            minHeight: 19,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      body: Focus(
        focusNode: _homeFocusNode,
        autofocus: true,
        onKeyEvent: handleHomeKeyboard,
        child: RefreshIndicator(
          onRefresh: refreshHome,
          child: ListView.builder(
            controller: _homeScrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            cacheExtent: 300,
            itemCount: 5,
            itemBuilder: (context, index) {
              if (index == 0) {
                return buildCategorySection();
              }

              return buildMovieSection(index);
            },
          ),
        ),
      ),
    );
  }
}
