# 🎬 CineMatch – Movie Discovery & Recommendation App##
🌐 Live Demo

**Website:https://cinematch-2504.web.app/

---

**Discover Movies. Explore Genres. Find Your Next Favourite Film!**

CineMatch is a movie discovery and recommendation application built using Flutter and Python. It helps users explore trending movies, discover movies by genre, search for their favourite films, view movie details, ratings, posters and trailers, and manage their personal watchlist.

The application integrates **The Movie Database (TMDB) API** for movie information and uses a Python-based backend to support movie recommendations and API communication.

---

## ✨ Features

- 🔥 **Trending Movies:** Explore currently trending movies.
- 🎥 **Popular Movies:** Discover popular movies from different categories.
- 🎭 **Genre-Based Categories:** Browse movies by Action, Comedy, Horror, Romance, Thriller, Sci-Fi and more.
- 🔍 **Smart Movie Search:** Search movies with autocomplete suggestions.
- ⭐ **Movie Ratings:** View movie ratings and information.
- 🖼️ **Movie Posters:** Browse movies with poster images.
- 📖 **Movie Details:** Explore descriptions and additional movie information.
- ▶️ **Movie Trailers:** Watch movie trailers.
- ❤️ **Watchlist:** Save movies to your personal watchlist.
- 🔐 **Firebase Authentication:** Register, log in and manage user authentication.
- 🤖 **Movie Recommendations:** Get movie suggestions using recommendation logic and MovieLens data.
- 📱 **Responsive Interface:** Designed for mobile and web experiences.

---

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Frontend development |
| Dart | Application programming |
| Python | Backend development |
| FastAPI | REST API development |
| TMDB API | Movie data and posters |
| Firebase Authentication | User authentication |
| MovieLens Dataset | Movie recommendation data |
| HTTP | API communication |
| Git & GitHub | Version control |

---

## 🏗️ Project Architecture

```text
             CineMatch Application
                      |
              Flutter Frontend
                      |
                Python Backend
                   (FastAPI)
                      |
          +-----------+-----------+
          |                       |
       TMDB API             MovieLens Dataset
          |                       |
    Movie Information       Recommendation
    Posters & Trailers         System
          |
       Firebase
   Authentication
```

---

## 📂 Project Structure

```text
CineMatch/
│
├── android/
├── assets/
├── lib/
│   ├── screens/
│   ├── widgets/
│   ├── services/
│   ├── models/
│   └── main.dart
│
├── backend/
│   ├── dataset/
│   │   ├── movies.csv
│   │   └── ratings.csv
│   │
│   ├── main.py
│   ├── recommender.py
│   ├── tmdb_service.py
│   ├── requirements.txt
│   └── .env
│
├── web/
├── pubspec.yaml
└── README.md
```

---

## 🚀 Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/abhi-2504/Cinematch.git
```

### 2. Navigate to the Project

```bash
cd Cinematch
```

### 3. Install Flutter Dependencies

```bash
flutter pub get
```

### 4. Backend Setup

Navigate to the backend folder:

```bash
cd backend
```

Create a Python virtual environment:

```bash
python -m venv venv
```

Activate the virtual environment on Windows:

```bash
venv\Scripts\activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

### 5. Configure Environment Variables

Create a `.env` file inside the backend folder:

```env
TMDB_ACCESS_TOKEN=your_tmdb_access_token
```

Replace the placeholder with your own TMDB API access token.

**Important:** Never upload your `.env` file or private API credentials to GitHub.

### 6. Run the Backend

```bash
uvicorn main:app --reload
```

Backend API:

```text
http://127.0.0.1:8000
```

### 7. Run the Flutter Application

Open another terminal in the project root:

```bash
flutter run
```

For web:

```bash
flutter run -d chrome
```

---

## 🔑 API & Services

- **TMDB API:** Provides movie information, posters, genres, trending movies and trailers.
- **Firebase Authentication:** Handles user registration and login.
- **MovieLens Dataset:** Supports the movie recommendation component.

You may need to configure your own API credentials and Firebase project before running the application.

---


## 🎯 Project Goal

The main goal of CineMatch is to make movie discovery easier and more enjoyable by combining movie browsing, genre-based exploration, search, personalized watchlists and recommendation functionality in one application.

---

## 👨‍💻 Developer

**Developed by: Abhinash**

GitHub: [@abhi-2504](https://github.com/abhi-2504)

Project: [CineMatch Repository](https://github.com/abhi-2504/Cinematch)

---

## 📄 Disclaimer

This project uses the TMDB API but is not endorsed or certified by TMDB.

Movie data and images are provided by TMDB. This project is developed for educational and learning purposes.

---

⭐ **If you find CineMatch interesting, consider giving this repository a star!**
