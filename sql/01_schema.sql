-- Spotify Music Streaming Database
-- CP1: Schema Design
-- PostgreSQL

CREATE SCHEMA IF NOT EXISTS spotify;

SET search_path TO spotify;

-- 1. Artists
CREATE TABLE artists (
    artist_id INTEGER PRIMARY KEY,
    artist_name TEXT NOT NULL,
    country_code VARCHAR(2) NOT NULL,
    primary_genre TEXT NOT NULL,
    is_verified BOOLEAN NOT NULL,
    monthly_listeners INTEGER NOT NULL
        CHECK (monthly_listeners >= 0),
    created_at TIMESTAMPTZ NOT NULL
);

-- 2. Users
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    country_code VARCHAR(2) NOT NULL,
    birth_date DATE NOT NULL,
    subscription TEXT NOT NULL
        CHECK (subscription IN ('DUO', 'FAMILY', 'FREE', 'PREMIUM', 'STUDENT')),
    created_at TIMESTAMPTZ NOT NULL
);

-- 3. Albums
CREATE TABLE albums (
    album_id INTEGER PRIMARY KEY,
    artist_id INTEGER NOT NULL REFERENCES artists(artist_id),
    album_title TEXT NOT NULL,
    album_type TEXT NOT NULL
        CHECK (album_type IN ('ALBUM', 'COMPILATION', 'EP', 'SINGLE')),
    release_date DATE NOT NULL,
    label TEXT NOT NULL,
    upc TEXT NOT NULL UNIQUE
);

-- 4. Tracks
CREATE TABLE tracks (
    track_id INTEGER PRIMARY KEY,
    album_id INTEGER NOT NULL REFERENCES albums(album_id),
    disc_no INTEGER NOT NULL CHECK (disc_no > 0),
    track_no INTEGER NOT NULL CHECK (track_no > 0),
    title TEXT NOT NULL,
    duration_ms INTEGER NOT NULL CHECK (duration_ms > 0),
    explicit BOOLEAN NOT NULL,
    isrc TEXT NOT NULL UNIQUE,
    popularity INTEGER NOT NULL CHECK (popularity BETWEEN 0 AND 100)
);

-- 5. Track artists (many-to-many)
CREATE TABLE track_artists (
    track_id INTEGER NOT NULL REFERENCES tracks(track_id),
    artist_id INTEGER NOT NULL REFERENCES artists(artist_id),
    role TEXT NOT NULL CHECK (role IN ('FEATURED', 'PRIMARY')),
    PRIMARY KEY (track_id, artist_id)
);

-- 6. Playlists
CREATE TABLE playlists (
    playlist_id INTEGER PRIMARY KEY,
    owner_user_id INTEGER NOT NULL REFERENCES users(user_id),
    name TEXT NOT NULL,
    is_public BOOLEAN NOT NULL,
    is_collaborative BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

-- 7. Playlist tracks
CREATE TABLE playlist_tracks (
    playlist_id INTEGER NOT NULL REFERENCES playlists(playlist_id),
    position INTEGER NOT NULL CHECK (position > 0),
    track_id INTEGER NOT NULL REFERENCES tracks(track_id),
    added_by_user_id INTEGER NOT NULL REFERENCES users(user_id),
    added_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (playlist_id, position)
);

-- 8. Streams
CREATE TABLE streams (
    stream_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id),
    track_id INTEGER NOT NULL REFERENCES tracks(track_id),
    started_at TIMESTAMPTZ NOT NULL,
    ms_played INTEGER NOT NULL CHECK (ms_played >= 0),
    platform TEXT NOT NULL
        CHECK (platform IN ('ANDROID', 'CAR', 'DESKTOP', 'IOS', 'SPEAKER', 'WEB')),
    source_type TEXT NOT NULL
        CHECK (source_type IN ('ALBUM', 'ARTIST', 'PLAYLIST', 'RADIO', 'SEARCH')),
    playlist_id INTEGER REFERENCES playlists(playlist_id),
    skipped BOOLEAN NOT NULL,
    offline BOOLEAN NOT NULL,

    CHECK (
        (source_type = 'PLAYLIST' AND playlist_id IS NOT NULL)
        OR
        (source_type <> 'PLAYLIST' AND playlist_id IS NULL)
    )
);

-- 9. Liked tracks
CREATE TABLE liked_tracks (
    user_id INTEGER NOT NULL REFERENCES users(user_id),
    track_id INTEGER NOT NULL REFERENCES tracks(track_id),
    liked_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id, track_id)
);

-- 10. Artist follows
CREATE TABLE artist_follows (
    user_id INTEGER NOT NULL REFERENCES users(user_id),
    artist_id INTEGER NOT NULL REFERENCES artists(artist_id),
    followed_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id, artist_id)
);
