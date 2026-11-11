# Spotify Music Streaming Platform – Problem Understanding

## 1. Project Overview

This project focuses on designing and optimizing a relational database for a Spotify-like music streaming platform. The platform manages artists, albums, tracks, users, playlists, listening activity, liked tracks, and artist followers.

The database must support both fast user-facing operations and large-scale analytical workloads while maintaining data consistency and supporting future growth.

## 2. Business Requirements

The platform requires efficient database operations for:

- Displaying artist profiles, album details, and track listings.
- Searching tracks and artists.
- Retrieving recently played tracks and liked songs.
- Managing playlists and collaborative playlist activity.
- Recording streams and calculating listening statistics.
- Tracking artist followers and listener engagement.
- Supporting royalty calculations and ISRC-based rights lookup.
- Generating reports such as listening trends, skip rates, and yearly listening summaries.
- Identifying compliance-related listening activity.
- Supporting future data growth and scalable analytical queries.

## 3. Stakeholders

- **Listeners:** Expect fast search, playlist, album, and listening-history operations.
- **Artists and labels:** Need accurate listener statistics, royalty information, and track metadata.
- **Platform administrators:** Manage users, content, compliance, and data quality.
- **Business and analytics teams:** Generate reports, discover trends, and evaluate platform performance.

## 4. Workload Classification

### Customer-facing and real-time workloads

These operations require low response times because they directly affect the user experience:

- Artist and album pages.
- Track and artist search.
- Recently played tracks.
- Liked songs.
- Playlist viewing and modification.
- Following artists.
- Recording new streams.

### Reporting and analytical workloads

These operations may process large volumes of historical data:

- Royalty and listening-duration calculations.
- Skip-rate and listener-engagement reports.
- Yearly listening summaries.
- Daily and monthly streaming trends.
- Public playlists that have never been played.
- Release discovery and recommendation analysis.
- Compliance reports.
- Large-scale analytics.

## 5. Performance and Scalability Challenges

The platform may experience slow queries when retrieving large playlists, searching historical listening activity, calculating artist statistics, and generating reports across millions of streams.

The database must therefore be designed with appropriate relationships and constraints, followed by query optimization, indexing, benchmarking, and partitioning where beneficial.

## 6. Assumptions

- Each album belongs to one artist.
- Each track belongs to one album.
- A track can be associated with multiple artists through the track-artists relationship.
- Each playlist has one owner and can contain multiple tracks.
- A user can like multiple tracks and follow multiple artists.
- A stream records one user's listening activity for one track.
- Playlist-source streams must reference a playlist; other source types do not.
- The initial dataset is supplied as CSV files and is used as the baseline workload dataset.

## 7. Project Objective

The objective is to build a reliable and normalized PostgreSQL database, evaluate its performance using a predefined workload, optimize expensive queries, and assess scalability under increased data volume.
