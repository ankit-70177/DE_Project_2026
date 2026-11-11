
\set ON_ERROR_STOP on

\copy spotify.artists (artist_id, artist_name, country_code, primary_genre, is_verified, monthly_listeners, created_at) FROM '/Users/RAdmin/Downloads/seed_data/artists.csv' WITH (FORMAT csv, HEADER true);

\copy spotify.users (user_id, email, display_name, country_code, birth_date, subscription, created_at) FROM '/Users/RAdmin/Downloads/seed_data/users.csv' WITH (FORMAT csv, HEADER true);

\copy spotify.albums (album_id, artist_id, album_title, album_type, release_date, label, upc) FROM '/Users/RAdmin/Downloads/seed_data/albums.csv' WITH (FORMAT csv, HEADER true);

\copy spotify.tracks (track_id, album_id, disc_no, track_no, title, duration_ms, explicit, isrc, popularity) FROM '/Users/RAdmin/Downloads/seed_data/tracks.csv' WITH (FORMAT csv, HEADER true);

\copy spotify.track_artists (track_id, artist_id, role) FROM '/Users/RAdmin/Downloads/seed_data/track_artists.csv' WITH (FORMAT csv, HEADER true);

\copy spotify.playlists (playlist_id, owner_user_id, name, is_public, is_collaborative, created_at) FROM '/Users/RAdmin/Downloads/seed_data/playlists.csv' WITH (FORMAT csv, HEADER true);

\copy spotify.playlist_tracks (playlist_id, position, track_id, added_by_user_id, added_at) FROM '/Users/RAdmin/Downloads/seed_data/playlist_tracks.csv' WITH (FORMAT csv, HEADER true);

\copy spotify.streams (stream_id, user_id, track_id, started_at, ms_played, platform, source_type, playlist_id, skipped, offline) FROM '/Users/RAdmin/Downloads/seed_data/streams.csv' WITH (FORMAT csv, HEADER true);

\copy spotify.liked_tracks (user_id, track_id, liked_at) FROM '/Users/RAdmin/Downloads/seed_data/liked_tracks.csv' WITH (FORMAT csv, HEADER true);

\copy spotify.artist_follows (user_id, artist_id, followed_at) FROM '/Users/RAdmin/Downloads/seed_data/artist_follows.csv' WITH (FORMAT csv, HEADER true);

ANALYZE;
