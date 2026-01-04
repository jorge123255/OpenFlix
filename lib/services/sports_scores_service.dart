import 'dart:async';

/// Model for a sports game/match
class SportsGame {
  final String id;
  final String sport; // e.g., 'nfl', 'nba', 'mlb', 'nhl', 'soccer'
  final String league;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int homeScore;
  final int awayScore;
  final String status; // 'scheduled', 'in_progress', 'final'
  final String? period; // e.g., 'Q1', '2nd Half', '3rd Period'
  final String? timeRemaining; // e.g., '5:32'
  final DateTime startTime;

  SportsGame({
    required this.id,
    required this.sport,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamLogo,
    this.awayTeamLogo,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    this.period,
    this.timeRemaining,
    required this.startTime,
  });

  bool get isLive => status == 'in_progress';
  bool get isFinal => status == 'final';
  bool get isScheduled => status == 'scheduled';

  String get statusDisplay {
    if (isLive) {
      if (period != null && timeRemaining != null) {
        return '$period - $timeRemaining';
      }
      return period ?? 'LIVE';
    }
    if (isFinal) return 'FINAL';
    return _formatTime(startTime);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  factory SportsGame.fromJson(Map<String, dynamic> json) {
    return SportsGame(
      id: json['id'] ?? '',
      sport: json['sport'] ?? '',
      league: json['league'] ?? '',
      homeTeam: json['homeTeam'] ?? '',
      awayTeam: json['awayTeam'] ?? '',
      homeTeamLogo: json['homeTeamLogo'],
      awayTeamLogo: json['awayTeamLogo'],
      homeScore: json['homeScore'] ?? 0,
      awayScore: json['awayScore'] ?? 0,
      status: json['status'] ?? 'scheduled',
      period: json['period'],
      timeRemaining: json['timeRemaining'],
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Service for fetching live sports scores
/// This is a stub implementation - integrate with a real sports API
/// (ESPN, SportsData.io, The Score, etc.)
class SportsScoresService {
  static SportsScoresService? _instance;
  final _scoresController = StreamController<List<SportsGame>>.broadcast();
  Timer? _refreshTimer;
  List<SportsGame> _currentGames = [];

  // Configurable API settings
  String? _apiKey;
  List<String> _enabledSports = ['nfl', 'nba', 'mlb', 'nhl', 'soccer'];

  SportsScoresService._();

  static SportsScoresService get instance {
    _instance ??= SportsScoresService._();
    return _instance!;
  }

  Stream<List<SportsGame>> get scoresStream => _scoresController.stream;
  List<SportsGame> get currentGames => _currentGames;

  void setApiKey(String? apiKey) {
    _apiKey = apiKey;
  }

  void setEnabledSports(List<String> sports) {
    _enabledSports = sports;
  }

  /// Start polling for live scores
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    stopPolling();
    _fetchScores();
    _refreshTimer = Timer.periodic(interval, (_) => _fetchScores());
  }

  /// Stop polling for scores
  void stopPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Fetch latest scores
  Future<void> _fetchScores() async {
    try {
      // TODO: Replace with actual API call when API key is configured
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        // Example API call (uncomment and modify for your sports API):
        // final response = await http.get(
        //   Uri.parse('https://api.sportsdata.io/v3/scores?apikey=$_apiKey'),
        // );
        // if (response.statusCode == 200) {
        //   final data = json.decode(response.body) as List;
        //   _currentGames = data.map((g) => SportsGame.fromJson(g)).toList();
        //   _scoresController.add(_currentGames);
        // }
      } else {
        // Use demo data when no API key is configured
        _currentGames = _getDemoGames();
        _scoresController.add(_currentGames);
      }
    } catch (e) {
      // Silently fail - scores are non-essential
    }
  }

  /// Get games for a specific sport
  List<SportsGame> getGamesForSport(String sport) {
    return _currentGames.where((g) => g.sport == sport).toList();
  }

  /// Get only live games
  List<SportsGame> get liveGames {
    return _currentGames.where((g) => g.isLive).toList();
  }

  /// Demo games for testing when no API is configured
  List<SportsGame> _getDemoGames() {
    return [
      SportsGame(
        id: 'demo1',
        sport: 'nfl',
        league: 'NFL',
        homeTeam: 'KC',
        awayTeam: 'BUF',
        homeScore: 24,
        awayScore: 21,
        status: 'in_progress',
        period: 'Q3',
        timeRemaining: '8:42',
        startTime: DateTime.now(),
      ),
      SportsGame(
        id: 'demo2',
        sport: 'nba',
        league: 'NBA',
        homeTeam: 'LAL',
        awayTeam: 'BOS',
        homeScore: 98,
        awayScore: 102,
        status: 'in_progress',
        period: '4th',
        timeRemaining: '3:15',
        startTime: DateTime.now(),
      ),
      SportsGame(
        id: 'demo3',
        sport: 'soccer',
        league: 'EPL',
        homeTeam: 'MAN UTD',
        awayTeam: 'MAN CITY',
        homeScore: 1,
        awayScore: 2,
        status: 'in_progress',
        period: '2nd Half',
        timeRemaining: '72\'',
        startTime: DateTime.now(),
      ),
    ];
  }

  void dispose() {
    stopPolling();
    _scoresController.close();
  }
}
