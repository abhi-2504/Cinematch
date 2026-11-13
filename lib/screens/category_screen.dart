
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/movie.dart';
import '../services/api_service.dart';
import '../widgets/movie_card.dart';
import 'details_screen.dart';

class CategoryScreen extends StatefulWidget {
  final int genreId;
  final String genreName;

  const CategoryScreen({
    super.key,
    required this.genreId,
    required this.genreName,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Movie>> moviesFuture;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    moviesFuture = ApiService.getMoviesByGenre(widget.genreId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void openMovie(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(movie: movie),
      ),
    );
  }

  int getColumnCount(double width) {
    if (width >= 1400) return 7;
    if (width >= 1100) return 6;
    if (width >= 850) return 5;
    if (width >= 600) return 4;
    if (width >= 400) return 3;
    return 2;
  }

  KeyEventResult handleKeyboard(
      FocusNode node,
      KeyEvent event,
      ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (!_scrollController.hasClients) {
      return KeyEventResult.ignored;
    }

    const scrollAmount = 250.0;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _scrollController.animateTo(
        (_scrollController.offset + scrollAmount)
            .clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );

      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _scrollController.animateTo(
        (_scrollController.offset - scrollAmount)
            .clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.genreName),
      ),
      body: FutureBuilder<List<Movie>>(
        future: moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load ${widget.genreName} movies.\n'
                    '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final movies = snapshot.data ?? [];

          if (movies.isEmpty) {
            return const Center(
              child: Text('No movies found.'),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = getColumnCount(
                constraints.maxWidth,
              );

              return Focus(
                focusNode: _keyboardFocusNode,
                autofocus: true,
                onKeyEvent: handleKeyboard,
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: movies.length,
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.50,
                  ),
                  itemBuilder: (context, index) {
                    final movie = movies[index];

                    return MovieCard(
                      movie: movie,
                      expand: true,
                      onTap: () => openMovie(movie),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
