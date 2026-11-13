from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import requests

from tmdb_service import (
    get_trending_movies,
    get_popular_movies,
    get_now_playing_movies,
    get_upcoming_movies,
    get_top_rated_movies,
    search_movies,
    get_movie_details,
    get_movie_credits,
    get_similar_movies,
    get_recommended_movies,
    get_genres,
    get_movies_by_genre,
    get_movie_trailer
    )



app = FastAPI(
    title="CineMatch API",
    description="Global Movie Discovery and Recommendation",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)


def handle_tmdb_error(error):
    if isinstance(error, requests.HTTPError):
        status = error.response.status_code

        if status == 404:
            raise HTTPException(
                status_code=404,
                detail="Movie not found"
            )

        if status == 401:
            raise HTTPException(
                status_code=502,
                detail="TMDB authentication failed. Check API token."
            )

    raise HTTPException(
        status_code=502,
        detail="Unable to fetch movie data from TMDB"
    )


@app.get("/")
def home():
    return {
        "app": "CineMatch",
        "message": "Backend is running",
        "version": "2.0.0"
    }


@app.get("/movies/trending")
def trending(
    page: int = Query(1, ge=1)
):
    try:
        return get_trending_movies(page)
    except requests.RequestException as error:
        handle_tmdb_error(error)


@app.get("/movies/popular")
def popular(
    page: int = Query(1, ge=1)
):
    try:
        return get_popular_movies(page)
    except requests.RequestException as error:
        handle_tmdb_error(error)


@app.get("/movies/now-playing")
def now_playing(
    page: int = Query(1, ge=1)
):
    try:
        return get_now_playing_movies(page)
    except requests.RequestException as error:
        handle_tmdb_error(error)


@app.get("/movies/upcoming")
def upcoming(
    page: int = Query(1, ge=1)
):
    try:
        return get_upcoming_movies(page)
    except requests.RequestException as error:
        handle_tmdb_error(error)


@app.get("/movies/top-rated")
def top_rated(
    page: int = Query(1, ge=1)
):
    try:
        return get_top_rated_movies(page)
    except requests.RequestException as error:
        handle_tmdb_error(error)


@app.get("/movies/search")
def search(
    q: str,
    page: int = Query(1, ge=1)
):
    if not q.strip():
        raise HTTPException(
            status_code=400,
            detail="Enter a movie name"
        )

    try:
        return search_movies(q.strip(), page)
    except requests.RequestException as error:
        handle_tmdb_error(error)


@app.get("/movies/genres")
def genres():
    try:
        return {"genres": get_genres()}
    except requests.RequestException as error:
        handle_tmdb_error(error)




@app.get("/movies/{movie_id}/credits")
def credits(movie_id: int):
    try:
        return get_movie_credits(movie_id)
    except requests.RequestException as error:
        handle_tmdb_error(error)


@app.get("/movies/{movie_id}/similar")
def similar(
    movie_id: int,
    page: int = Query(1, ge=1)
):
    try:
        return get_similar_movies(movie_id, page)
    except requests.RequestException as error:
        handle_tmdb_error(error)


@app.get("/movies/{movie_id}/recommendations")
def recommendations(
    movie_id: int,
    page: int = Query(1, ge=1)
):
    try:
        return get_recommended_movies(movie_id, page)
    except requests.RequestException as error:
        handle_tmdb_error(error)


@app.get("/movies/{movie_id}/trailer")
def movie_trailer(movie_id: int):
    try:
        return get_movie_trailer(movie_id)
    except requests.RequestException as error:
        handle_tmdb_error(error)

@app.get("/movies/{movie_id}")
def details(movie_id: int):
    try:
        return get_movie_details(movie_id)
    except requests.RequestException as error:
        handle_tmdb_error(error)

@app.get("/movies/genre/{genre_id}")
def movies_by_genre(
    genre_id: int,
    page: int = Query(1, ge=1)
):
    try:
        return get_movies_by_genre(genre_id, page)
    except requests.RequestException as error:
        handle_tmdb_error(error)

