enum AppHiveBox {
  settings(false),
  timeline(false),
  releases(true),
  player(true),
  downloads(false),
  pdfCache(false),
  mp3Cache(false),
  stats(false),
  favoriteItems(false),
  directory(false),
  nupale(false),
  casete(false),
  profile(false),
  games(false),
  blog(false),
  posts(true),         // Feed cache with limit
  visitedProfiles(true), // Recently visited profiles cache
  inbox(false),        // Messages cache
  syncQueue(false);    // Offline actions queue

  final bool limit;
  const AppHiveBox(this.limit);
}
