
import os
import time
import logging
import threading
from collections import OrderedDict

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from dotenv import load_dotenv

load_dotenv()

# Configuration
BASE_URL = "https://api.themoviedb.org/3"
IMAGE_URL = "https://image.tmdb.org/t/p"

TOKEN = os.getenv("TMDB_ACCESS_TOKEN")

if not TOKEN:
    raise RuntimeError(
        "TMDB_ACCESS_TOKEN missing. Check backend/.env"
    )

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "accept": "application/json"
}

# Logging
logger = logging.getLogger(__name__)

# HTTP Session with automatic retry
session = requests.Session()

retry_strategy = Retry(
    total=3,
    connect=3,
    read=3,
    status=3,
    backoff_factor=1,
    status_forcelist=[429, 500, 502, 503, 504],
    allowed_methods=["GET"],
    respect_retry_after_header=True
)

adapter = HTTPAdapter(max_retries=retry_strategy)

session.mount("https://", adapter)
session.mount("http://", adapter)

# Response cache
CACHE = OrderedDict()
CACHE_LOCK = threading.Lock()

CACHE_TTL = 300
CACHE_MAX_SIZE = 200


def get_cache_key(endpoint, params):
    params = params or {}

    return (
        endpoint,
        tuple(sorted(params.items()))
    )


def tmdb_request(endpoint, params=None):

    params = params or {}
    cache_key = get_cache_key(endpoint, params)

    # Check cache
    with CACHE_LOCK:
        cached = CACHE.get(cache_key)

        if cached:
            data, expiry = cached

            if time.time() < expiry:
                CACHE.move_to_end(cache_key)
                logger.info("TMDB cache hit: %s", endpoint)
                return data

            del CACHE[cache_key]

    # API request
    url = f"{BASE_URL}/{endpoint.lstrip('/')}"

    try:
        response = session.get(
            url,
            headers=HEADERS,
            params=params,
            timeout=(5, 20)
        )

        response.raise_for_status()

        data = response.json()

        # Store successful response in cache
        with CACHE_LOCK:
            CACHE[cache_key] = (
                data,
                time.time() + CACHE_TTL
            )

            CACHE.move_to_end(cache_key)

            while len(CACHE) > CACHE_MAX_SIZE:
                CACHE.popitem(last=False)

        return data

    except requests.HTTPError as error:
        status = error.response.status_code if error.response is not None else 500

        logger.error(
            "TMDB HTTP error %s: %s",
            status,
            endpoint
        )
        raise

    except requests.Timeout:
        logger.error("TMDB request timed out: %s", endpoint)
        raise

    except requests.RequestException:
        logger.exception("TMDB connection error: %s", endpoint)
        raise

    except ValueError:
        logger.exception("Invalid JSON response from TMDB")
        raise


def format_movie(movie):

    poster = movie.get("poster_path")
    backdrop = movie.get("backdrop_path")

    return {
        "id": movie.get("id"),
        "title": movie.get("title"),
        "original_title": movie.get("original_title"),
        "overview": movie.get("overview"),
        "release_date": movie.get("release_date"),
        "genre_ids": movie.get("genre_ids", []),
        "vote_average": movie.get("vote_average"),
        "vote_count": movie.get("vote_count"),

        "poster_url": (
            f"{IMAGE_URL}/w500{poster}"
            if poster else None
        ),

        "backdrop_url": (
            f"{IMAGE_URL}/original{backdrop}"
            if backdrop else None
        )
    }


def format_movie_list(data):

    return {
        "page": data.get("page", 1),
        "total_pages": data.get("total_pages", 1),
        "total_results": data.get("total_results", 0),

        "results": [
            format_movie(movie)
            for movie in data.get("results", [])
        ]
    }


def get_movie_list(endpoint, page=1):

    data = tmdb_request(
        endpoint,
        params={
            "language": "en-US",
            "page": page
        }
    )

    return format_movie_list(data)


def get_trending_movies(page=1):
    return get_movie_list(
        "trending/movie/week", page
    )


def get_popular_movies(page=1):
    return get_movie_list(
        "movie/popular", page
    )


def get_now_playing_movies(page=1):
    return get_movie_list(
        "movie/now_playing", page
    )


def get_upcoming_movies(page=1):
    return get_movie_list(
        "movie/upcoming", page
    )


def get_top_rated_movies(page=1):
    return get_movie_list(
        "movie/top_rated", page
    )


def search_movies(query, page=1):

    data = tmdb_request(
        "search/movie",
        params={
            "query": query,
            "include_adult": False,
            "language": "en-US",
            "page": page
        }
    )

    return format_movie_list(data)


def get_movie_details(movie_id):

    data = tmdb_request(
        f"movie/{movie_id}",
        params={"language": "en-US"}
    )

    movie = format_movie(data)

    movie["genres"] = data.get("genres", [])
    movie["runtime"] = data.get("runtime")
    movie["status"] = data.get("status")
    movie["imdb_id"] = data.get("imdb_id")

    if movie["imdb_id"]:
        movie["imdb_url"] = (
            "https://www.imdb.com/title/"
            + movie["imdb_id"]
            + "/"
        )
    else:
        movie["imdb_url"] = None

    return movie


def get_movie_credits(movie_id):

    data = tmdb_request(
        f"movie/{movie_id}/credits"
    )

    return {
        "cast": data.get("cast", [])[:20],
        "crew": data.get("crew", [])
    }


def get_similar_movies(movie_id, page=1):

    return get_movie_list(
        f"movie/{movie_id}/similar", page
    )


def get_recommended_movies(movie_id, page=1):

    return get_movie_list(
        f"movie/{movie_id}/recommendations", page
    )


def get_genres():

    data = tmdb_request(
        "genre/movie/list",
        params={"language": "en-US"}
    )

    return data.get("genres", [])

def get_movies_by_genre(genre_id, page=1):

    data = tmdb_request(
        "discover/movie",
        params={
            "with_genres": genre_id,
            "language": "en-US",
            "sort_by": "popularity.desc",
            "include_adult": False,
            "page": page
        }
    )

    return format_movie_list(data)

def get_movie_trailer(movie_id):
    data = tmdb_request(
        f"movie/{movie_id}/videos",
        params={
            "language": "en-US"
        }
    )

    videos = data.get("results", [])

    # Prefer official YouTube trailers.
    trailers = [
        video for video in videos
        if video.get("site") == "YouTube"
        and video.get("type") == "Trailer"
        and video.get("key")
    ]

    official_trailers = [
        video for video in trailers
        if video.get("official") is True
    ]

    selected = (
        official_trailers[0]
        if official_trailers
        else trailers[0] if trailers
        else None
    )

    if not selected:
        return {
            "available": False,
            "youtube_key": None,
            "name": None
        }

    return {
        "available": True,
        "youtube_key": selected.get("key"),
        "name": selected.get("name"),
        "site": "YouTube",
        "type": "Trailer"
    }
