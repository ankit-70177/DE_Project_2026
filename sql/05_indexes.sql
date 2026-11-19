-- CP3 indexes for the measured 250k-stream workload.
-- Equality keys precede time/order keys where applicable.
SET search_path TO spotify;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- R01, R07, R10, R12, R16, R20, R23: time-window/order scans.
-- INCLUDE columns support R23's projected columns from the index.
CREATE INDEX IF NOT EXISTS idx_streams_started_at_cover
    ON streams (started_at DESC)
    INCLUDE (stream_id, user_id, track_id, ms_played, platform, skipped, offline);

-- R04, R09, R17: user-specific stream history/windows, newest first.
CREATE INDEX IF NOT EXISTS idx_streams_user_started_at
    ON streams (user_id, started_at DESC)
    INCLUDE (track_id, ms_played, platform);

-- R01, R08, R25: streams reached by track, with time available for joins.
CREATE INDEX IF NOT EXISTS idx_streams_track_started_at
    ON streams (track_id, started_at)
    INCLUDE (stream_id, user_id, ms_played, skipped);

-- R01, R07, R08, R15, R16, R19: artist-to-track mapping lookups.
CREATE INDEX IF NOT EXISTS idx_track_artists_artist_track
    ON track_artists (artist_id, track_id)
    INCLUDE (role);

-- R02: album tracklist lookup in requested order; covers its projection.
CREATE INDEX IF NOT EXISTS idx_tracks_album_disc_track
    ON tracks (album_id, disc_no, track_no)
    INCLUDE (title, duration_ms, explicit);

-- R03: leading-wildcard ILIKE title search.
CREATE INDEX IF NOT EXISTS idx_tracks_title_trgm
    ON tracks USING GIN (title gin_trgm_ops);

-- R11, R25: artist release lookup and newest releases.
CREATE INDEX IF NOT EXISTS idx_albums_artist_release
    ON albums (artist_id, release_date DESC)
    INCLUDE (album_id, album_title, album_type);

-- R13: only playlist-origin streams establish that a playlist was played.
CREATE INDEX IF NOT EXISTS idx_streams_playlist_played
    ON streams (playlist_id)
    WHERE playlist_id IS NOT NULL;

-- R14: aggregate distinct contributors per collaborative playlist.
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_playlist_adder
    ON playlist_tracks (playlist_id, added_by_user_id);

-- R22, W05: group tracks per playlist and find containing playlists.
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_track_playlist
    ON playlist_tracks (track_id, playlist_id);


-- R15: find all followers of the seed artist, then join their other follows.
CREATE INDEX IF NOT EXISTS idx_artist_follows_artist_user
    ON artist_follows (artist_id, user_id);

-- R22: group duplicate playlist-track pairs in the same key order.
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_playlist_track
    ON playlist_tracks (playlist_id, track_id);

ANALYZE;
