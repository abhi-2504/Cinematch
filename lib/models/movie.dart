class Movie {
  final int id;
  final String title;
  final String overview;
  final String releaseDate;
  final double rating;
  final int voteCount;
  final List<int> genreIds;
  final String? posterUrl;
  final String? backdropUrl;
  final String? imdbId;
  final String? imdbUrl;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.releaseDate,
    required this.rating,
    required this.voteCount,
    required this.genreIds,
    this.posterUrl,
    this.backdropUrl,
    this.imdbId,
    this.imdbUrl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Movie',
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? '',
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
      voteCount: json['vote_count'] ?? 0,
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      posterUrl: json['poster_url'],
      backdropUrl: json['backdrop_url'],
      imdbId: json['imdb_id'],
      imdbUrl: json['imdb_url'],
    );
  }

  String get releaseYear {
    if (releaseDate.length >= 4) {
      return releaseDate.substring(0, 4);
    }
    return 'N/A';
  }
}