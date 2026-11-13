
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final bool expand;

  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : 140,
      child: RepaintBoundary(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: movie.posterUrl != null &&
                      movie.posterUrl!.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: movie.posterUrl!,
                    fit: BoxFit.cover,

                    // Reduce decoded image memory.
                    memCacheWidth: 420,
                    maxWidthDiskCache: 600,

                    fadeInDuration:
                    const Duration(milliseconds: 150),

                    placeholder: (context, url) {
                      return Container(
                        color: Colors.white10,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },

                    errorWidget: (context, url, error) {
                      return Container(
                        color: Colors.white10,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.movie,
                          size: 32,
                        ),
                      );
                    },
                  )
                      : Container(
                    color: Colors.white10,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.movie,
                      size: 32,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 4),

                  Text(movie.rating.toStringAsFixed(1)),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      movie.releaseYear,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
