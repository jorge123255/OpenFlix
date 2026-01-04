import '../services/settings_service.dart' as settings;

/// Content rating levels for movies (MPAA ratings)
const List<String> movieRatings = ['G', 'PG', 'PG-13', 'R', 'NC-17'];

/// Content rating levels for TV shows
const List<String> tvRatings = ['TV-Y', 'TV-Y7', 'TV-G', 'TV-PG', 'TV-14', 'TV-MA'];

/// Get the numeric level of a movie rating (higher = more mature)
int getMovieRatingLevel(String rating) {
  final normalized = _normalizeRating(rating);
  final index = movieRatings.indexOf(normalized);
  return index >= 0 ? index : movieRatings.length; // Unknown ratings treated as highest
}

/// Get the numeric level of a TV rating (higher = more mature)
int getTvRatingLevel(String rating) {
  final normalized = _normalizeRating(rating);
  final index = tvRatings.indexOf(normalized);
  return index >= 0 ? index : tvRatings.length; // Unknown ratings treated as highest
}

/// Normalize a rating string by removing country prefixes
String _normalizeRating(String? rating) {
  if (rating == null || rating.isEmpty) return '';

  // Remove common country prefixes like "gb/", "us/", "de/", etc.
  final regex = RegExp(r'^[a-z]{2,3}/(.+)$', caseSensitive: false);
  final match = regex.firstMatch(rating);

  String normalized = match != null && match.groupCount >= 1
      ? match.group(1) ?? rating
      : rating;

  // Normalize common variations
  normalized = normalized.toUpperCase().trim();

  // Map common variations to standard ratings
  const variations = {
    'NR': 'NC-17', // Not Rated - treat as highest
    'UNRATED': 'NC-17',
    'MA': 'TV-MA',
    'TV-MA-V': 'TV-MA',
    'TV-MA-S': 'TV-MA',
    'TV-MA-L': 'TV-MA',
    'TV-14-V': 'TV-14',
    'TV-14-S': 'TV-14',
    'TV-14-L': 'TV-14',
    'TV-PG-V': 'TV-PG',
    'TV-PG-S': 'TV-PG',
    'TV-PG-L': 'TV-PG',
  };

  return variations[normalized] ?? normalized;
}

/// Check if content is allowed based on parental control settings
Future<bool> isContentAllowed(
  String? contentRating,
  bool isMovie,
  settings.SettingsService settingsService,
) async {
  // If parental controls are disabled, allow everything
  if (!settingsService.getParentalControlsEnabled()) {
    return true;
  }

  // If content is temporarily unlocked, allow everything
  if (settingsService.isRestrictedContentUnlocked()) {
    return true;
  }

  // No rating means we can't determine - allow it
  if (contentRating == null || contentRating.isEmpty) {
    return true;
  }

  final normalized = _normalizeRating(contentRating);

  if (isMovie) {
    final maxRating = settingsService.getMaxMovieRating();
    final contentLevel = getMovieRatingLevel(normalized);
    final maxLevel = getMovieRatingLevel(maxRating);
    return contentLevel <= maxLevel;
  } else {
    final maxRating = settingsService.getMaxTvRating();
    final contentLevel = getTvRatingLevel(normalized);
    final maxLevel = getTvRatingLevel(maxRating);
    return contentLevel <= maxLevel;
  }
}

/// Check if content is restricted (for showing lock icon, etc.)
bool isContentRestricted(
  String? contentRating,
  bool isMovie,
  settings.SettingsService settingsService,
) {
  // If parental controls are disabled, nothing is restricted
  if (!settingsService.getParentalControlsEnabled()) {
    return false;
  }

  // No rating means we can't determine - not restricted
  if (contentRating == null || contentRating.isEmpty) {
    return false;
  }

  final normalized = _normalizeRating(contentRating);

  if (isMovie) {
    final maxRating = settingsService.getMaxMovieRating();
    final contentLevel = getMovieRatingLevel(normalized);
    final maxLevel = getMovieRatingLevel(maxRating);
    return contentLevel > maxLevel;
  } else {
    final maxRating = settingsService.getMaxTvRating();
    final contentLevel = getTvRatingLevel(normalized);
    final maxLevel = getTvRatingLevel(maxRating);
    return contentLevel > maxLevel;
  }
}

/// Get display name for a movie rating
String getMovieRatingDisplayName(String rating) {
  switch (rating) {
    case 'G':
      return 'G (General Audience)';
    case 'PG':
      return 'PG (Parental Guidance)';
    case 'PG-13':
      return 'PG-13 (Parents Cautioned)';
    case 'R':
      return 'R (Restricted)';
    case 'NC-17':
      return 'NC-17 (Adults Only)';
    default:
      return rating;
  }
}

/// Get display name for a TV rating
String getTvRatingDisplayName(String rating) {
  switch (rating) {
    case 'TV-Y':
      return 'TV-Y (All Children)';
    case 'TV-Y7':
      return 'TV-Y7 (Ages 7+)';
    case 'TV-G':
      return 'TV-G (General Audience)';
    case 'TV-PG':
      return 'TV-PG (Parental Guidance)';
    case 'TV-14':
      return 'TV-14 (Ages 14+)';
    case 'TV-MA':
      return 'TV-MA (Mature Audience)';
    default:
      return rating;
  }
}
