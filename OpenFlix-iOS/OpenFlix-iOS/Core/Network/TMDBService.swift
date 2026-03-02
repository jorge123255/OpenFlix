import Foundation

// MARK: - TMDB Service
// Fetches movie trailers from The Movie Database API
// API key is fetched from the OpenFlix server

actor TMDBService {
    static let shared = TMDBService()

    // TMDB API key - fetched from server
    private var apiKey: String?
    private var apiKeyLoaded = false
    private var apiKeyLoadTask: Task<Void, Never>?
    private let baseURL = "https://api.themoviedb.org/3"

    private let session: URLSession
    private let decoder: JSONDecoder

    // Cache trailers to avoid repeated API calls
    private var trailerCache: [String: TrailerInfo?] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - Public API

    /// Fetch trailer for a movie by TMDB ID
    func getTrailer(tmdbId: String) async -> TrailerInfo? {
        // Check cache first
        if let cached = trailerCache[tmdbId] {
            return cached
        }

        // Ensure API key is loaded from server
        await ensureApiKeyLoaded()

        // Skip if no API key available
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            NSLog("TMDBService: No API key available from server")
            return nil
        }

        do {
            let trailer = try await fetchTrailer(tmdbId: tmdbId, apiKey: apiKey)
            trailerCache[tmdbId] = trailer
            return trailer
        } catch {
            NSLog("TMDBService: Failed to fetch trailer for \(tmdbId): \(error)")
            trailerCache[tmdbId] = nil
            return nil
        }
    }

    /// Load API key from server (called automatically when needed)
    private func ensureApiKeyLoaded() async {
        // If already loaded, return immediately
        if apiKeyLoaded {
            return
        }

        // If there's already a loading task, wait for it
        if let existingTask = apiKeyLoadTask {
            await existingTask.value
            return
        }

        // Create a new loading task
        let task = Task<Void, Never> {
            do {
                let response = try await OpenFlixAPI.shared.getServerSettings()
                self.apiKey = response.settings.tmdbApiKey
                if let key = self.apiKey, !key.isEmpty {
                    NSLog("TMDBService: Loaded TMDB API key from server: %@....", String(key.prefix(8)))
                } else {
                    NSLog("TMDBService: Server has no TMDB API key configured")
                }
            } catch {
                NSLog("TMDBService: Failed to load API key from server: \(error.localizedDescription)")
            }
            self.apiKeyLoaded = true
        }
        apiKeyLoadTask = task
        await task.value
    }

    /// Force reload API key from server (e.g., after settings change)
    func reloadApiKey() async {
        apiKeyLoaded = false
        apiKeyLoadTask = nil
        await ensureApiKeyLoaded()
    }

    /// Extract TMDB ID from Plex GUID
    /// Plex stores GUIDs like "plex://movie/5d776..." or "tmdb://12345" or "com.plexapp.agents.themoviedb://12345"
    func extractTMDBId(from guid: String?) -> String? {
        guard let guid = guid else { return nil }

        // Direct TMDB ID: "tmdb://12345"
        if guid.hasPrefix("tmdb://") {
            return String(guid.dropFirst("tmdb://".count))
        }

        // Legacy agent format: "com.plexapp.agents.themoviedb://12345?lang=en"
        if guid.contains("themoviedb://") {
            if let range = guid.range(of: "themoviedb://") {
                let afterPrefix = guid[range.upperBound...]
                // Extract ID before any query params
                let id = afterPrefix.split(separator: "?").first.map(String.init) ?? String(afterPrefix)
                return id
            }
        }

        return nil
    }

    /// Search TMDB for a movie by title and year, returns the TMDB ID if found
    func searchMovie(title: String, year: Int?) async -> String? {
        await ensureApiKeyLoaded()

        guard let apiKey = apiKey, !apiKey.isEmpty else {
            NSLog("TMDBService: Cannot search - no API key available")
            return nil
        }

        NSLog("TMDBService: Searching for movie '\(title)' (year: \(year ?? 0))")

        // Build search URL
        var urlString = "\(baseURL)/search/movie?api_key=\(apiKey)&query=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title)"
        if let year = year {
            urlString += "&year=\(year)"
        }

        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let searchResponse = try decoder.decode(TMDBSearchResponse.self, from: data)

            // Return the first result's ID
            if let firstResult = searchResponse.results.first {
                NSLog("TMDBService: Found TMDB match for '\(title)': ID \(firstResult.id)")
                return String(firstResult.id)
            }
        } catch {
            NSLog("TMDBService: Search failed for '\(title)': \(error)")
        }

        return nil
    }

    /// Get trailer by searching for movie title (fallback when no GUID)
    func getTrailerByTitle(title: String, year: Int?) async -> TrailerInfo? {
        // Search for the movie first
        guard let tmdbId = await searchMovie(title: title, year: year) else {
            NSLog("TMDBService: No TMDB match found for '\(title)'")
            return nil
        }

        // Then get the trailer
        return await getTrailer(tmdbId: tmdbId)
    }

    // MARK: - Private API

    private func fetchTrailer(tmdbId: String, apiKey: String) async throws -> TrailerInfo? {
        // Fetch movie details to get backdrop path
        let backdropPath = await fetchBackdropPath(tmdbId: tmdbId, apiKey: apiKey)

        let urlString = "\(baseURL)/movie/\(tmdbId)/videos?api_key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TMDBError.requestFailed
        }

        let videosResponse = try decoder.decode(TMDBVideosResponse.self, from: data)

        // Find the best trailer: prefer official trailers from YouTube
        let trailers = videosResponse.results.filter { video in
            video.site.lowercased() == "youtube" &&
            video.type.lowercased() == "trailer"
        }

        // Prefer official trailers
        if let official = trailers.first(where: { $0.official == true }) {
            return TrailerInfo(youtubeKey: official.key, name: official.name, backdropPath: backdropPath)
        }

        // Fall back to any trailer
        if let trailer = trailers.first {
            return TrailerInfo(youtubeKey: trailer.key, name: trailer.name, backdropPath: backdropPath)
        }

        // Try teasers if no trailers available
        if let teaser = videosResponse.results.first(where: {
            $0.site.lowercased() == "youtube" && $0.type.lowercased() == "teaser"
        }) {
            return TrailerInfo(youtubeKey: teaser.key, name: teaser.name, backdropPath: backdropPath)
        }

        return nil
    }

    /// Fetch movie details to get the backdrop path
    private func fetchBackdropPath(tmdbId: String, apiKey: String) async -> String? {
        let urlString = "\(baseURL)/movie/\(tmdbId)?api_key=\(apiKey)"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            let movieDetails = try decoder.decode(TMDBMovieDetails.self, from: data)
            return movieDetails.backdropPath
        } catch {
            NSLog("TMDBService: Failed to fetch backdrop for \(tmdbId): \(error)")
            return nil
        }
    }

    /// Clear the trailer cache
    func clearCache() {
        trailerCache.removeAll()
    }

    // MARK: - Full Movie Details

    /// Fetch complete movie details from TMDB (for movies without server metadata)
    func getMovieDetails(title: String, year: Int?) async -> TMDBMovieInfo? {
        await ensureApiKeyLoaded()

        guard let apiKey = apiKey, !apiKey.isEmpty else {
            NSLog("TMDBService: Cannot fetch movie details - no API key available")
            return nil
        }

        // First search for the movie
        guard let tmdbId = await searchMovie(title: title, year: year) else {
            NSLog("TMDBService: No TMDB match found for '\(title)'")
            return nil
        }

        // Fetch full details with credits
        return await fetchMovieDetails(tmdbId: tmdbId, apiKey: apiKey)
    }

    /// Fetch movie details including cast, genres, and full overview
    private func fetchMovieDetails(tmdbId: String, apiKey: String) async -> TMDBMovieInfo? {
        // Use append_to_response to get credits in one call
        let urlString = "\(baseURL)/movie/\(tmdbId)?api_key=\(apiKey)&append_to_response=credits"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            let details = try decoder.decode(TMDBFullMovieDetails.self, from: data)

            // Convert to our simpler model
            return TMDBMovieInfo(
                tmdbId: details.id,
                title: details.title,
                overview: details.overview,
                backdropPath: details.backdropPath,
                posterPath: details.posterPath,
                releaseDate: details.releaseDate,
                runtime: details.runtime,
                voteAverage: details.voteAverage,
                genres: details.genres?.map { $0.name } ?? [],
                cast: details.credits?.cast?.prefix(10).map { castMember in
                    TMDBCastMember(
                        name: castMember.name,
                        character: castMember.character,
                        profilePath: castMember.profilePath
                    )
                } ?? [],
                directors: details.credits?.crew?.filter { $0.job == "Director" }.map { $0.name } ?? [],
                writers: details.credits?.crew?.filter { $0.job == "Writer" || $0.job == "Screenplay" }.map { $0.name } ?? []
            )
        } catch {
            NSLog("TMDBService: Failed to fetch movie details for \(tmdbId): \(error)")
            return nil
        }
    }
}

// MARK: - TMDB Response Models

struct TMDBSearchResponse: Codable {
    let page: Int
    let results: [TMDBSearchResult]
    let totalResults: Int?
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalResults = "total_results"
        case totalPages = "total_pages"
    }
}

struct TMDBSearchResult: Codable {
    let id: Int
    let title: String
    let originalTitle: String?
    let releaseDate: String?
    let posterPath: String?
    let backdropPath: String?
    let overview: String?

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case originalTitle = "original_title"
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
}

struct TMDBMovieDetails: Codable {
    let id: Int
    let title: String
    let backdropPath: String?
    let posterPath: String?
    let overview: String?

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
    }
}

// Full movie details with credits
struct TMDBFullMovieDetails: Codable {
    let id: Int
    let title: String
    let overview: String?
    let backdropPath: String?
    let posterPath: String?
    let releaseDate: String?
    let runtime: Int?
    let voteAverage: Double?
    let genres: [TMDBGenre]?
    let credits: TMDBCredits?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres, credits
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }
}

struct TMDBGenre: Codable {
    let id: Int
    let name: String
}

struct TMDBCredits: Codable {
    let cast: [TMDBCast]?
    let crew: [TMDBCrew]?
}

struct TMDBCast: Codable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let order: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, character, order
        case profilePath = "profile_path"
    }
}

struct TMDBCrew: Codable {
    let id: Int
    let name: String
    let job: String
    let department: String?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, job, department
        case profilePath = "profile_path"
    }
}

// Simplified movie info for use in the app
struct TMDBMovieInfo {
    let tmdbId: Int
    let title: String
    let overview: String?
    let backdropPath: String?
    let posterPath: String?
    let releaseDate: String?
    let runtime: Int?
    let voteAverage: Double?
    let genres: [String]
    let cast: [TMDBCastMember]
    let directors: [String]
    let writers: [String]

    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(path)")
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
}

struct TMDBCastMember {
    let name: String
    let character: String?
    let profilePath: String?

    var profileURL: URL? {
        guard let path = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
    }
}

struct TMDBVideosResponse: Codable {
    let id: Int
    let results: [TMDBVideo]
}

struct TMDBVideo: Codable {
    let id: String
    let key: String  // YouTube video ID
    let name: String
    let site: String  // "YouTube", "Vimeo", etc.
    let type: String  // "Trailer", "Teaser", "Featurette", etc.
    let official: Bool?
    let publishedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, key, name, site, type, official
        case publishedAt = "published_at"
    }
}

// MARK: - TMDB Errors

enum TMDBError: Error {
    case invalidURL
    case requestFailed
    case decodingError
    case noTrailerFound
}
