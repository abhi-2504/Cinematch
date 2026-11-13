import pandas as pd
import numpy as np

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

movies = pd.read_csv("dataset/movies.csv")

movies = movies.dropna(
    subset=["title", "genres"]
).reset_index(drop=True)

vectorizer = TfidfVectorizer()

tfidf_matrix = vectorizer.fit_transform(
    movies["genres"]
)

def recommend_movies(movie_title, limit=10):

    matches = movies[
        movies["title"].str.contains(
            movie_title,
            case=False,
            regex=False
        )
    ]

    if matches.empty:
        return []

    movie_index = matches.index[0]

    scores = cosine_similarity(
        tfidf_matrix[movie_index],
        tfidf_matrix
    ).flatten()

    similar_indices = np.argsort(scores)[::-1]

    similar_indices = [
        i for i in similar_indices
        if i != movie_index
    ][:limit]

    results = movies.iloc[similar_indices]

    return results[
        ["movieId", "title", "genres"]
    ].to_dict(orient="records")