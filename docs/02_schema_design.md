# Spotify Music Streaming Database – Schema Design

## 1. Overview

The Spotify Music Streaming Database is implemented using PostgreSQL. It consists of 10 relational tables designed to manage artists, users, albums, tracks, playlists, streaming activity, likes, and artist followers.

All tables are organized under the `spotify` schema. The design uses primary keys, foreign keys, unique constraints, NOT NULL constraints, and CHECK constraints to maintain data integrity.

## 2. Database Tables and Attributes

### 2.1 Artists

Stores information about music artists.

| Attribute | Data Type | Constraint |
|---|---|---|
| artist_id | INTEGER | Primary Key |
| artist_name | TEXT | NOT NULL |
| country_code | VARCHAR(2) | NOT NULL |
| primary_genre | TEXT | NOT NULL |
| is_verified | BOOLEAN | NOT NULL |
| monthly_listeners | INTEGER | NOT NULL, CHECK >= 0 |
| created_at | TIMESTAMPTZ | NOT NULL |

### 2.2 Users

Stores registered platform users and their subscription details.

| Attribute | Data Type | Constraint |
|---|---|---|
| user_id | INTEGER | Primary Key |
| email | TEXT | NOT NULL, UNIQUE |
| display_name | TEXT | NOT NULL |
| country_code | VARCHAR(2) | NOT NULL |
| birth_date | DATE | NOT NULL |
| subscription | TEXT | NOT NULL, CHECK |
| created_at | TIMESTAMPTZ | NOT NULL |

Allowed subscription values: DUO, FAMILY, FREE, PREMIUM, STUDENT.

### 2.3 Albums

Stores album metadata and the artist associated with each album.

| Attribute | Data Type | Constraint |
|---|---|---|
| album_id | INTEGER | Primary Key |
| artist_id | INTEGER | Foreign Key → artists |
| album_title | TEXT | NOT NULL |
| album_type | TEXT | NOT NULL, CHECK |
| release_date | DATE | NOT NULL |
| label | TEXT | NOT NULL |
| upc | TEXT | NOT NULL, UNIQUE |

Allowed album types: ALBUM, COMPILATION, EP, SINGLE.

### 2.4 Tracks

Stores individual track information.

| Attribute | Data Type | Constraint |
|---|---|---|
| track_id | INTEGER | Primary Key |
| album_id | INTEGER | Foreign Key → albums |
| disc_no | INTEGER | NOT NULL, CHECK > 0 |
| track_no | INTEGER | NOT NULL, CHECK > 0 |
| title | TEXT | NOT NULL |
| duration_ms | INTEGER | NOT NULL, CHECK > 0 |
| explicit | BOOLEAN | NOT NULL |
| isrc | TEXT | NOT NULL, UNIQUE |
| popularity | INTEGER | NOT NULL, CHECK 0–100 |

### 2.5 Track Artists

Implements the many-to-many relationship between tracks and artists.

| Attribute | Data Type | Constraint |
|---|---|---|
| track_id | INTEGER | Foreign Key → tracks |
| artist_id | INTEGER | Foreign Key → artists |
| role | TEXT | NOT NULL, CHECK |

Composite Primary Key: `(track_id, artist_id)`.

Allowed roles: PRIMARY, FEATURED.

### 2.6 Playlists

Stores playlists created by users.

| Attribute | Data Type | Constraint |
|---|---|---|
| playlist_id | INTEGER | Primary Key |
| owner_user_id | INTEGER | Foreign Key → users |
| name | TEXT | NOT NULL |
| is_public | BOOLEAN | NOT NULL |
| is_collaborative | BOOLEAN | NOT NULL |
| created_at | TIMESTAMPTZ | NOT NULL |

### 2.7 Playlist Tracks

Stores tracks added to playlists and their positions.

| Attribute | Data Type | Constraint |
|---|---|---|
| playlist_id | INTEGER | Foreign Key → playlists |
| position | INTEGER | NOT NULL, CHECK > 0 |
| track_id | INTEGER | Foreign Key → tracks |
| added_by_user_id | INTEGER | Foreign Key → users |
| added_at | TIMESTAMPTZ | NOT NULL |

Composite Primary Key: `(playlist_id, position)`.

### 2.8 Streams

Records user listening activity.

| Attribute | Data Type | Constraint |
|---|---|---|
| stream_id | INTEGER | Primary Key |
| user_id | INTEGER | Foreign Key → users |
| track_id | INTEGER | Foreign Key → tracks |
| started_at | TIMESTAMPTZ | NOT NULL |
| ms_played | INTEGER | NOT NULL, CHECK >= 0 |
| platform | TEXT | NOT NULL, CHECK |
| source_type | TEXT | NOT NULL, CHECK |
| playlist_id | INTEGER | Nullable Foreign Key → playlists |
| skipped | BOOLEAN | NOT NULL |
| offline | BOOLEAN | NOT NULL |

Allowed platforms: ANDROID, CAR, DESKTOP, IOS, SPEAKER, WEB.

Allowed source types: ALBUM, ARTIST, PLAYLIST, RADIO, SEARCH.

A CHECK constraint ensures that playlist_id is populated for PLAYLIST source streams and NULL for all other source types.

### 2.9 Liked Tracks

Stores the tracks liked by users.

| Attribute | Data Type | Constraint |
|---|---|---|
| user_id | INTEGER | Foreign Key → users |
| track_id | INTEGER | Foreign Key → tracks |
| liked_at | TIMESTAMPTZ | NOT NULL |

Composite Primary Key: `(user_id, track_id)`.

### 2.10 Artist Follows

Stores relationships between users and artists they follow.

| Attribute | Data Type | Constraint |
|---|---|---|
| user_id | INTEGER | Foreign Key → users |
| artist_id | INTEGER | Foreign Key → artists |
| followed_at | TIMESTAMPTZ | NOT NULL |

Composite Primary Key: `(user_id, artist_id)`.

## 3. Primary Keys and Foreign Keys

### Primary Keys

- artists: artist_id
- users: user_id
- albums: album_id
- tracks: track_id
- track_artists: (track_id, artist_id)
- playlists: playlist_id
- playlist_tracks: (playlist_id, position)
- streams: stream_id
- liked_tracks: (user_id, track_id)
- artist_follows: (user_id, artist_id)

### Foreign Key Relationships

1. albums.artist_id → artists.artist_id
2. tracks.album_id → albums.album_id
3. track_artists.track_id → tracks.track_id
4. track_artists.artist_id → artists.artist_id
5. playlists.owner_user_id → users.user_id
6. playlist_tracks.playlist_id → playlists.playlist_id
7. playlist_tracks.track_id → tracks.track_id
8. playlist_tracks.added_by_user_id → users.user_id
9. streams.user_id → users.user_id
10. streams.track_id → tracks.track_id
11. streams.playlist_id → playlists.playlist_id
12. liked_tracks.user_id → users.user_id
13. liked_tracks.track_id → tracks.track_id
14. artist_follows.user_id → users.user_id
15. artist_follows.artist_id → artists.artist_id

## 4. Relationship Cardinalities

- Artists to Albums: One-to-Many.
- Albums to Tracks: One-to-Many.
- Tracks to Artists: Many-to-Many through track_artists.
- Users to Playlists: One-to-Many.
- Playlists to Tracks: Many-to-Many through playlist_tracks.
- Users to Tracks: Many-to-Many through liked_tracks.
- Users to Artists: Many-to-Many through artist_follows.
- Users to Streams: One-to-Many.
- Tracks to Streams: One-to-Many.
- Playlists to Streams: One-to-Many, optional for streams because not every stream originates from a playlist.

## 5. Functional Dependencies

The following functional dependencies are established by the declared keys:

- artists: artist_id → all other artist attributes.
- users: user_id → all other user attributes; email → other user attributes because email is UNIQUE.
- albums: album_id → all other album attributes; upc → other album attributes because UPC is UNIQUE.
- tracks: track_id → all other track attributes; isrc → other track attributes because ISRC is UNIQUE.
- track_artists: (track_id, artist_id) → role.
- playlists: playlist_id → all other playlist attributes.
- playlist_tracks: (playlist_id, position) → track_id, added_by_user_id, added_at.
- streams: stream_id → all other stream attributes.
- liked_tracks: (user_id, track_id) → liked_at.
- artist_follows: (user_id, artist_id) → followed_at.

## 6. Normalization

### First Normal Form (1NF)

All tables contain atomic values, and each row is uniquely identifiable using a primary key. Repeating groups and multivalued attributes are separated into relationship tables.

### Second Normal Form (2NF)

The tables with composite primary keys contain attributes that depend on the complete key:

- track_artists: role depends on both track_id and artist_id.
- playlist_tracks: added_by_user_id, track_id, and added_at depend on playlist_id and position.
- liked_tracks: liked_at depends on user_id and track_id.
- artist_follows: followed_at depends on user_id and artist_id.

The remaining tables use single-column primary keys.

### Third Normal Form (3NF)

Non-key attributes depend on their table's key, with no intentionally stored transitive dependencies identified in the relational design.

The many-to-many relationships are separated into junction tables to avoid repeating groups and update anomalies.

### BCNF

The declared candidate-key functional dependencies in the base tables have candidate keys as their determinants. The schema is designed to satisfy BCNF under these declared dependencies.

## 7. Integrity Constraints

The schema enforces:

- Primary key constraints for all 10 tables.
- 15 foreign key relationships.
- Unique constraints on users.email, albums.upc, and tracks.isrc.
- NOT NULL constraints on mandatory attributes.
- CHECK constraints for valid subscription types, album types, track roles, platform values, source types, positive positions and durations, valid popularity ranges, non-negative listening durations and monthly listeners, and playlist-source consistency.

There are 12 CHECK constraints in total.

## 8. Design Decisions and Assumptions

1. `track_artists` uses `(track_id, artist_id)` as its composite primary key because the dataset contains no duplicate track-artist pairs.
2. `playlist_tracks` uses `(playlist_id, position)` as its primary key because each position must be unique within a playlist. The same track may appear at different positions.
3. `streams.playlist_id` is nullable because streams can originate from albums, artists, radio, or search.
4. `artists.monthly_listeners` is maintained as a stored statistic for faster access and may require periodic updates.
5. `streams.skipped` is stored as an event attribute rather than derived from `ms_played`, because the exact business definition of a skipped stream is not enforced by the schema.
6. `albums.artist_id` represents the album's associated artist, while `track_artists` records the artists credited on each individual track.
7. All timestamps use TIMESTAMPTZ to preserve timezone-aware event information.

## 9. Dataset Summary

The database was populated from 10 CSV files.

| Table | Loaded Rows |
|---|---:|
| artists | 3,000 |
| users | 30,000 |
| albums | 12,000 |
| tracks | 67,808 |
| track_artists | 77,489 |
| playlists | 10,000 |
| playlist_tracks | 120,004 |
| streams | 250,000 |
| liked_tracks | 58,533 |
| artist_follows | 69,901 |
| **Total** | **698,735** |

Four integrity checks were executed successfully:

- No tracks reference missing albums.
- No tracks are missing a PRIMARY artist.
- Playlist-source stream references are consistent.
- Album artists match the PRIMARY artists of their tracks.

All four checks returned zero invalid records.

## 10. Conclusion

The database schema provides a structured relational foundation for the music streaming platform. It supports the core business entities, enforces referential integrity, minimizes unnecessary duplication, and provides a foundation for workload benchmarking, indexing, query optimization, and scalability analysis.
