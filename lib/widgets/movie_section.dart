import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/movie.dart';
import '../services/api_service.dart';
import 'movie_card.dart';

typedef MoviePageLoader = Future<MoviePage> Function(int page);

class MovieSection extends StatefulWidget {
  final String title;
  final MoviePageLoader loadPage;
  final Function(Movie) onMovieTap;

  const MovieSection({
    super.key,
    required this.title,
    required this.loadPage,
    required this.onMovieTap,
  });

  @override
  State<MovieSection> createState() => MovieSectionState();
}

class MovieSectionState extends State<MovieSection>
    with AutomaticKeepAliveClientMixin<MovieSection> {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _rowController = ScrollController();
  final FocusNode _rowFocusNode = FocusNode();

  final List<Movie> _movies = [];
  final Set<int> _movieIds = {};

  static const double _scrollAmount = 180.0;
  static const double _loadThreshold = 500.0;

  int _currentPage = 0;
  int _totalPages = 1;
  int _requestGeneration = 0;

  bool _initialLoading = true;
  bool _initialRequestRunning = false;
  bool _loadingMore = false;
  bool _hasError = false;

  String? _errorMessage;
  String? _loadMoreError;

  bool get _hasMore => _currentPage < _totalPages;

  @override
  void initState() {
    super.initState();

    _rowController.addListener(_onScroll);

    _loadInitialPage();
  }

  @override
  void dispose() {
    _requestGeneration++;

    _rowController.removeListener(_onScroll);
    _rowController.dispose();

    _rowFocusNode.dispose();

    super.dispose();
  }

  // Refresh the movie section.
  Future<void> refresh() async {
    // Invalidate all previous requests.
    _requestGeneration++;

    if (_rowController.hasClients) {
      _rowController.jumpTo(0);
    }

    if (!mounted) return;

    setState(() {
      _movies.clear();
      _movieIds.clear();

      _currentPage = 0;
      _totalPages = 1;

      _initialLoading = true;
      _initialRequestRunning = false;
      _loadingMore = false;

      _hasError = false;

      _errorMessage = null;
      _loadMoreError = null;
    });

    await _loadInitialPage();
  }

  // Load the first page.
  Future<void> _loadInitialPage() async {
    if (!mounted || _initialRequestRunning) return;

    final requestId = ++_requestGeneration;

    setState(() {
      _initialLoading = true;
      _initialRequestRunning = true;

      _hasError = false;
      _errorMessage = null;
    });

    try {
      final result = await widget.loadPage(1);

      // Ignore outdated responses.
      if (!mounted || requestId != _requestGeneration) return;

      setState(() {
        _movies
          ..clear()
          ..addAll(result.movies);

        _movieIds
          ..clear()
          ..addAll(result.movies.map((movie) => movie.id));

        _currentPage = result.page;
        _totalPages = result.totalPages;

        _initialLoading = false;
        _initialRequestRunning = false;

        _hasError = false;
        _errorMessage = null;
      });

      // Check if more pages should be loaded.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onScroll();
        }
      });
    } catch (e) {
      if (!mounted || requestId != _requestGeneration) return;

      setState(() {
        _initialLoading = false;
        _initialRequestRunning = false;

        _hasError = true;
        _errorMessage = 'Unable to load movies. Please try again.';
      });

      debugPrint('${widget.title} initial loading failed: $e');
    }
  }

  // Detect horizontal scroll position.
  void _onScroll() {
    if (!mounted ||
        !_rowController.hasClients ||
        _initialLoading ||
        _loadingMore ||
        !_hasMore ||
        _hasError) {
      return;
    }

    if (_rowController.position.extentAfter < _loadThreshold) {
      _loadNextPage();
    }
  }

  // Load the next page.
  Future<void> _loadNextPage() async {
    if (!mounted || _loadingMore || _initialLoading || !_hasMore) {
      return;
    }

    final nextPage = _currentPage + 1;
    final requestId = _requestGeneration;

    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });

    try {
      final result = await widget.loadPage(nextPage);

      // Ignore response if refresh happened meanwhile.
      if (!mounted || requestId != _requestGeneration) return;

      setState(() {
        for (final movie in result.movies) {
          if (_movieIds.add(movie.id)) {
            _movies.add(movie);
          }
        }

        _currentPage = result.page;
        _totalPages = result.totalPages;

        _loadingMore = false;
        _loadMoreError = null;
      });

      // Continue pagination if row is still near the end.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onScroll();
        }
      });
    } catch (e) {
      if (!mounted || requestId != _requestGeneration) return;

      setState(() {
        _loadingMore = false;
        _loadMoreError = 'Unable to load more movies';
      });

      debugPrint('${widget.title} next page failed: $e');
    }
  }

  // Keyboard horizontal scrolling.
  KeyEventResult _handleRowKeyboard(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_rowController.hasClients) {
      return KeyEventResult.ignored;
    }

    double? target;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      target = _rowController.offset + _scrollAmount;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      target = _rowController.offset - _scrollAmount;
    }

    if (target == null) {
      return KeyEventResult.ignored;
    }

    final position = _rowController.position;

    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);

    _rowController.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );

    return KeyEventResult.handled;
  }

  // Initial loading error UI.
  Widget _buildInitialError() {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white54, size: 28),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to load movies',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadInitialPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Pagination loading indicator.
  Widget _buildLoadMoreIndicator() {
    if (_loadMoreError != null) {
      return SizedBox(
        width: 110,
        child: Center(
          child: IconButton(
            tooltip: 'Retry loading movies',
            onPressed: _loadNextPage,
            icon: const Icon(Icons.refresh, color: Colors.redAccent, size: 30),
          ),
        ),
      );
    }

    if (_loadingMore) {
      return const SizedBox(
        width: 90,
        child: Center(
          child: SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    return const SizedBox(width: 25);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        // Movie list.
        SizedBox(
          height: 275,
          child: _initialLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? _buildInitialError()
              : _movies.isEmpty
              ? const Center(child: Text('No movies available'))
              : MouseRegion(
                  onEnter: (_) {
                    _rowFocusNode.requestFocus();
                  },
                  child: Focus(
                    focusNode: _rowFocusNode,
                    onKeyEvent: _handleRowKeyboard,
                    child: ListView.separated(
                      key: PageStorageKey<String>(
                        'movie-section-${widget.title}',
                      ),
                      controller: _rowController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _movies.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        if (index >= _movies.length) {
                          return _buildLoadMoreIndicator();
                        }

                        final movie = _movies[index];

                        return MovieCard(
                          key: ValueKey(movie.id),
                          movie: movie,
                          onTap: () {
                            widget.onMovieTap(movie);
                          },
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
