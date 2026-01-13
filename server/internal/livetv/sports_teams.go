package livetv

import "strings"

// SportsTeam represents a sports team with its aliases
type SportsTeam struct {
	Name     string   // Full team name (e.g., "Chicago Bears")
	City     string   // City name (e.g., "Chicago")
	Nickname string   // Nickname (e.g., "Bears")
	Aliases  []string // Additional aliases for matching
	League   string   // League code (NFL, NBA, MLB, NHL, MLS)
	LogoCode string   // Code for logo URL (e.g., "chi" for ESPN CDN)
}

// GetLogoURL returns the team's logo URL from ESPN CDN
func (t *SportsTeam) GetLogoURL() string {
	if t.LogoCode == "" {
		return ""
	}
	league := strings.ToLower(t.League)
	if league == "mls" {
		// MLS uses soccer category with team IDs
		return "https://a.espncdn.com/i/teamlogos/soccer/500/" + t.LogoCode + ".png"
	}
	return "https://a.espncdn.com/i/teamlogos/" + league + "/500/" + t.LogoCode + ".png"
}

// SportsTeamDB contains all known sports teams
var SportsTeamDB = map[string][]SportsTeam{
	"NFL": {
		{Name: "Arizona Cardinals", City: "Arizona", Nickname: "Cardinals", Aliases: []string{"ARI", "Cards"}, League: "NFL", LogoCode: "ari"},
		{Name: "Atlanta Falcons", City: "Atlanta", Nickname: "Falcons", Aliases: []string{"ATL"}, League: "NFL", LogoCode: "atl"},
		{Name: "Baltimore Ravens", City: "Baltimore", Nickname: "Ravens", Aliases: []string{"BAL"}, League: "NFL", LogoCode: "bal"},
		{Name: "Buffalo Bills", City: "Buffalo", Nickname: "Bills", Aliases: []string{"BUF"}, League: "NFL", LogoCode: "buf"},
		{Name: "Carolina Panthers", City: "Carolina", Nickname: "Panthers", Aliases: []string{"CAR"}, League: "NFL", LogoCode: "car"},
		{Name: "Chicago Bears", City: "Chicago", Nickname: "Bears", Aliases: []string{"CHI"}, League: "NFL", LogoCode: "chi"},
		{Name: "Cincinnati Bengals", City: "Cincinnati", Nickname: "Bengals", Aliases: []string{"CIN"}, League: "NFL", LogoCode: "cin"},
		{Name: "Cleveland Browns", City: "Cleveland", Nickname: "Browns", Aliases: []string{"CLE"}, League: "NFL", LogoCode: "cle"},
		{Name: "Dallas Cowboys", City: "Dallas", Nickname: "Cowboys", Aliases: []string{"DAL"}, League: "NFL", LogoCode: "dal"},
		{Name: "Denver Broncos", City: "Denver", Nickname: "Broncos", Aliases: []string{"DEN"}, League: "NFL", LogoCode: "den"},
		{Name: "Detroit Lions", City: "Detroit", Nickname: "Lions", Aliases: []string{"DET"}, League: "NFL", LogoCode: "det"},
		{Name: "Green Bay Packers", City: "Green Bay", Nickname: "Packers", Aliases: []string{"GB", "GNB"}, League: "NFL", LogoCode: "gb"},
		{Name: "Houston Texans", City: "Houston", Nickname: "Texans", Aliases: []string{"HOU"}, League: "NFL", LogoCode: "hou"},
		{Name: "Indianapolis Colts", City: "Indianapolis", Nickname: "Colts", Aliases: []string{"IND"}, League: "NFL", LogoCode: "ind"},
		{Name: "Jacksonville Jaguars", City: "Jacksonville", Nickname: "Jaguars", Aliases: []string{"JAX", "JAC", "Jags"}, League: "NFL", LogoCode: "jax"},
		{Name: "Kansas City Chiefs", City: "Kansas City", Nickname: "Chiefs", Aliases: []string{"KC", "KAN"}, League: "NFL", LogoCode: "kc"},
		{Name: "Las Vegas Raiders", City: "Las Vegas", Nickname: "Raiders", Aliases: []string{"LV", "LVR", "Oakland Raiders"}, League: "NFL", LogoCode: "lv"},
		{Name: "Los Angeles Chargers", City: "Los Angeles", Nickname: "Chargers", Aliases: []string{"LAC", "San Diego Chargers"}, League: "NFL", LogoCode: "lac"},
		{Name: "Los Angeles Rams", City: "Los Angeles", Nickname: "Rams", Aliases: []string{"LAR", "St. Louis Rams"}, League: "NFL", LogoCode: "lar"},
		{Name: "Miami Dolphins", City: "Miami", Nickname: "Dolphins", Aliases: []string{"MIA"}, League: "NFL", LogoCode: "mia"},
		{Name: "Minnesota Vikings", City: "Minnesota", Nickname: "Vikings", Aliases: []string{"MIN"}, League: "NFL", LogoCode: "min"},
		{Name: "New England Patriots", City: "New England", Nickname: "Patriots", Aliases: []string{"NE", "NEP", "Pats"}, League: "NFL", LogoCode: "ne"},
		{Name: "New Orleans Saints", City: "New Orleans", Nickname: "Saints", Aliases: []string{"NO", "NOS"}, League: "NFL", LogoCode: "no"},
		{Name: "New York Giants", City: "New York", Nickname: "Giants", Aliases: []string{"NYG"}, League: "NFL", LogoCode: "nyg"},
		{Name: "New York Jets", City: "New York", Nickname: "Jets", Aliases: []string{"NYJ"}, League: "NFL", LogoCode: "nyj"},
		{Name: "Philadelphia Eagles", City: "Philadelphia", Nickname: "Eagles", Aliases: []string{"PHI"}, League: "NFL", LogoCode: "phi"},
		{Name: "Pittsburgh Steelers", City: "Pittsburgh", Nickname: "Steelers", Aliases: []string{"PIT"}, League: "NFL", LogoCode: "pit"},
		{Name: "San Francisco 49ers", City: "San Francisco", Nickname: "49ers", Aliases: []string{"SF", "SFO", "Niners"}, League: "NFL", LogoCode: "sf"},
		{Name: "Seattle Seahawks", City: "Seattle", Nickname: "Seahawks", Aliases: []string{"SEA"}, League: "NFL", LogoCode: "sea"},
		{Name: "Tampa Bay Buccaneers", City: "Tampa Bay", Nickname: "Buccaneers", Aliases: []string{"TB", "TBB", "Bucs"}, League: "NFL", LogoCode: "tb"},
		{Name: "Tennessee Titans", City: "Tennessee", Nickname: "Titans", Aliases: []string{"TEN"}, League: "NFL", LogoCode: "ten"},
		{Name: "Washington Commanders", City: "Washington", Nickname: "Commanders", Aliases: []string{"WAS", "WSH", "Washington Football Team", "Redskins"}, League: "NFL", LogoCode: "wsh"},
	},
	"NBA": {
		{Name: "Atlanta Hawks", City: "Atlanta", Nickname: "Hawks", Aliases: []string{"ATL"}, League: "NBA", LogoCode: "atl"},
		{Name: "Boston Celtics", City: "Boston", Nickname: "Celtics", Aliases: []string{"BOS"}, League: "NBA", LogoCode: "bos"},
		{Name: "Brooklyn Nets", City: "Brooklyn", Nickname: "Nets", Aliases: []string{"BKN", "New Jersey Nets"}, League: "NBA", LogoCode: "bkn"},
		{Name: "Charlotte Hornets", City: "Charlotte", Nickname: "Hornets", Aliases: []string{"CHA", "Bobcats"}, League: "NBA", LogoCode: "cha"},
		{Name: "Chicago Bulls", City: "Chicago", Nickname: "Bulls", Aliases: []string{"CHI"}, League: "NBA", LogoCode: "chi"},
		{Name: "Cleveland Cavaliers", City: "Cleveland", Nickname: "Cavaliers", Aliases: []string{"CLE", "Cavs"}, League: "NBA", LogoCode: "cle"},
		{Name: "Dallas Mavericks", City: "Dallas", Nickname: "Mavericks", Aliases: []string{"DAL", "Mavs"}, League: "NBA", LogoCode: "dal"},
		{Name: "Denver Nuggets", City: "Denver", Nickname: "Nuggets", Aliases: []string{"DEN"}, League: "NBA", LogoCode: "den"},
		{Name: "Detroit Pistons", City: "Detroit", Nickname: "Pistons", Aliases: []string{"DET"}, League: "NBA", LogoCode: "det"},
		{Name: "Golden State Warriors", City: "Golden State", Nickname: "Warriors", Aliases: []string{"GSW", "GS", "Dubs"}, League: "NBA", LogoCode: "gs"},
		{Name: "Houston Rockets", City: "Houston", Nickname: "Rockets", Aliases: []string{"HOU"}, League: "NBA", LogoCode: "hou"},
		{Name: "Indiana Pacers", City: "Indiana", Nickname: "Pacers", Aliases: []string{"IND"}, League: "NBA", LogoCode: "ind"},
		{Name: "Los Angeles Clippers", City: "Los Angeles", Nickname: "Clippers", Aliases: []string{"LAC"}, League: "NBA", LogoCode: "lac"},
		{Name: "Los Angeles Lakers", City: "Los Angeles", Nickname: "Lakers", Aliases: []string{"LAL"}, League: "NBA", LogoCode: "lal"},
		{Name: "Memphis Grizzlies", City: "Memphis", Nickname: "Grizzlies", Aliases: []string{"MEM"}, League: "NBA", LogoCode: "mem"},
		{Name: "Miami Heat", City: "Miami", Nickname: "Heat", Aliases: []string{"MIA"}, League: "NBA", LogoCode: "mia"},
		{Name: "Milwaukee Bucks", City: "Milwaukee", Nickname: "Bucks", Aliases: []string{"MIL"}, League: "NBA", LogoCode: "mil"},
		{Name: "Minnesota Timberwolves", City: "Minnesota", Nickname: "Timberwolves", Aliases: []string{"MIN", "Wolves", "T-Wolves"}, League: "NBA", LogoCode: "min"},
		{Name: "New Orleans Pelicans", City: "New Orleans", Nickname: "Pelicans", Aliases: []string{"NOP", "NO", "Hornets"}, League: "NBA", LogoCode: "no"},
		{Name: "New York Knicks", City: "New York", Nickname: "Knicks", Aliases: []string{"NYK"}, League: "NBA", LogoCode: "ny"},
		{Name: "Oklahoma City Thunder", City: "Oklahoma City", Nickname: "Thunder", Aliases: []string{"OKC"}, League: "NBA", LogoCode: "okc"},
		{Name: "Orlando Magic", City: "Orlando", Nickname: "Magic", Aliases: []string{"ORL"}, League: "NBA", LogoCode: "orl"},
		{Name: "Philadelphia 76ers", City: "Philadelphia", Nickname: "76ers", Aliases: []string{"PHI", "Sixers"}, League: "NBA", LogoCode: "phi"},
		{Name: "Phoenix Suns", City: "Phoenix", Nickname: "Suns", Aliases: []string{"PHX"}, League: "NBA", LogoCode: "phx"},
		{Name: "Portland Trail Blazers", City: "Portland", Nickname: "Trail Blazers", Aliases: []string{"POR", "Blazers"}, League: "NBA", LogoCode: "por"},
		{Name: "Sacramento Kings", City: "Sacramento", Nickname: "Kings", Aliases: []string{"SAC"}, League: "NBA", LogoCode: "sac"},
		{Name: "San Antonio Spurs", City: "San Antonio", Nickname: "Spurs", Aliases: []string{"SAS", "SA"}, League: "NBA", LogoCode: "sa"},
		{Name: "Toronto Raptors", City: "Toronto", Nickname: "Raptors", Aliases: []string{"TOR"}, League: "NBA", LogoCode: "tor"},
		{Name: "Utah Jazz", City: "Utah", Nickname: "Jazz", Aliases: []string{"UTA"}, League: "NBA", LogoCode: "uta"},
		{Name: "Washington Wizards", City: "Washington", Nickname: "Wizards", Aliases: []string{"WAS", "WSH", "Bullets"}, League: "NBA", LogoCode: "wsh"},
	},
	"MLB": {
		{Name: "Arizona Diamondbacks", City: "Arizona", Nickname: "Diamondbacks", Aliases: []string{"ARI", "D-backs"}, League: "MLB", LogoCode: "ari"},
		{Name: "Atlanta Braves", City: "Atlanta", Nickname: "Braves", Aliases: []string{"ATL"}, League: "MLB", LogoCode: "atl"},
		{Name: "Baltimore Orioles", City: "Baltimore", Nickname: "Orioles", Aliases: []string{"BAL", "O's"}, League: "MLB", LogoCode: "bal"},
		{Name: "Boston Red Sox", City: "Boston", Nickname: "Red Sox", Aliases: []string{"BOS", "BoSox"}, League: "MLB", LogoCode: "bos"},
		{Name: "Chicago Cubs", City: "Chicago", Nickname: "Cubs", Aliases: []string{"CHC"}, League: "MLB", LogoCode: "chc"},
		{Name: "Chicago White Sox", City: "Chicago", Nickname: "White Sox", Aliases: []string{"CHW", "CWS", "Sox"}, League: "MLB", LogoCode: "chw"},
		{Name: "Cincinnati Reds", City: "Cincinnati", Nickname: "Reds", Aliases: []string{"CIN"}, League: "MLB", LogoCode: "cin"},
		{Name: "Cleveland Guardians", City: "Cleveland", Nickname: "Guardians", Aliases: []string{"CLE", "Indians"}, League: "MLB", LogoCode: "cle"},
		{Name: "Colorado Rockies", City: "Colorado", Nickname: "Rockies", Aliases: []string{"COL"}, League: "MLB", LogoCode: "col"},
		{Name: "Detroit Tigers", City: "Detroit", Nickname: "Tigers", Aliases: []string{"DET"}, League: "MLB", LogoCode: "det"},
		{Name: "Houston Astros", City: "Houston", Nickname: "Astros", Aliases: []string{"HOU"}, League: "MLB", LogoCode: "hou"},
		{Name: "Kansas City Royals", City: "Kansas City", Nickname: "Royals", Aliases: []string{"KC", "KCR"}, League: "MLB", LogoCode: "kc"},
		{Name: "Los Angeles Angels", City: "Los Angeles", Nickname: "Angels", Aliases: []string{"LAA", "Anaheim Angels"}, League: "MLB", LogoCode: "laa"},
		{Name: "Los Angeles Dodgers", City: "Los Angeles", Nickname: "Dodgers", Aliases: []string{"LAD"}, League: "MLB", LogoCode: "lad"},
		{Name: "Miami Marlins", City: "Miami", Nickname: "Marlins", Aliases: []string{"MIA", "Florida Marlins"}, League: "MLB", LogoCode: "mia"},
		{Name: "Milwaukee Brewers", City: "Milwaukee", Nickname: "Brewers", Aliases: []string{"MIL"}, League: "MLB", LogoCode: "mil"},
		{Name: "Minnesota Twins", City: "Minnesota", Nickname: "Twins", Aliases: []string{"MIN"}, League: "MLB", LogoCode: "min"},
		{Name: "New York Mets", City: "New York", Nickname: "Mets", Aliases: []string{"NYM"}, League: "MLB", LogoCode: "nym"},
		{Name: "New York Yankees", City: "New York", Nickname: "Yankees", Aliases: []string{"NYY", "Yanks"}, League: "MLB", LogoCode: "nyy"},
		{Name: "Oakland Athletics", City: "Oakland", Nickname: "Athletics", Aliases: []string{"OAK", "A's"}, League: "MLB", LogoCode: "oak"},
		{Name: "Philadelphia Phillies", City: "Philadelphia", Nickname: "Phillies", Aliases: []string{"PHI"}, League: "MLB", LogoCode: "phi"},
		{Name: "Pittsburgh Pirates", City: "Pittsburgh", Nickname: "Pirates", Aliases: []string{"PIT", "Bucs"}, League: "MLB", LogoCode: "pit"},
		{Name: "San Diego Padres", City: "San Diego", Nickname: "Padres", Aliases: []string{"SD", "SDP"}, League: "MLB", LogoCode: "sd"},
		{Name: "San Francisco Giants", City: "San Francisco", Nickname: "Giants", Aliases: []string{"SF", "SFG"}, League: "MLB", LogoCode: "sf"},
		{Name: "Seattle Mariners", City: "Seattle", Nickname: "Mariners", Aliases: []string{"SEA", "M's"}, League: "MLB", LogoCode: "sea"},
		{Name: "St. Louis Cardinals", City: "St. Louis", Nickname: "Cardinals", Aliases: []string{"STL", "Cards"}, League: "MLB", LogoCode: "stl"},
		{Name: "Tampa Bay Rays", City: "Tampa Bay", Nickname: "Rays", Aliases: []string{"TB", "TBR", "Devil Rays"}, League: "MLB", LogoCode: "tb"},
		{Name: "Texas Rangers", City: "Texas", Nickname: "Rangers", Aliases: []string{"TEX"}, League: "MLB", LogoCode: "tex"},
		{Name: "Toronto Blue Jays", City: "Toronto", Nickname: "Blue Jays", Aliases: []string{"TOR", "Jays"}, League: "MLB", LogoCode: "tor"},
		{Name: "Washington Nationals", City: "Washington", Nickname: "Nationals", Aliases: []string{"WAS", "WSH", "Nats"}, League: "MLB", LogoCode: "wsh"},
	},
	"NHL": {
		{Name: "Anaheim Ducks", City: "Anaheim", Nickname: "Ducks", Aliases: []string{"ANA", "Mighty Ducks"}, League: "NHL", LogoCode: "ana"},
		{Name: "Arizona Coyotes", City: "Arizona", Nickname: "Coyotes", Aliases: []string{"ARI", "Phoenix Coyotes"}, League: "NHL", LogoCode: "ari"},
		{Name: "Boston Bruins", City: "Boston", Nickname: "Bruins", Aliases: []string{"BOS"}, League: "NHL", LogoCode: "bos"},
		{Name: "Buffalo Sabres", City: "Buffalo", Nickname: "Sabres", Aliases: []string{"BUF"}, League: "NHL", LogoCode: "buf"},
		{Name: "Calgary Flames", City: "Calgary", Nickname: "Flames", Aliases: []string{"CGY"}, League: "NHL", LogoCode: "cgy"},
		{Name: "Carolina Hurricanes", City: "Carolina", Nickname: "Hurricanes", Aliases: []string{"CAR", "Canes"}, League: "NHL", LogoCode: "car"},
		{Name: "Chicago Blackhawks", City: "Chicago", Nickname: "Blackhawks", Aliases: []string{"CHI", "Hawks"}, League: "NHL", LogoCode: "chi"},
		{Name: "Colorado Avalanche", City: "Colorado", Nickname: "Avalanche", Aliases: []string{"COL", "Avs"}, League: "NHL", LogoCode: "col"},
		{Name: "Columbus Blue Jackets", City: "Columbus", Nickname: "Blue Jackets", Aliases: []string{"CBJ"}, League: "NHL", LogoCode: "cbj"},
		{Name: "Dallas Stars", City: "Dallas", Nickname: "Stars", Aliases: []string{"DAL"}, League: "NHL", LogoCode: "dal"},
		{Name: "Detroit Red Wings", City: "Detroit", Nickname: "Red Wings", Aliases: []string{"DET"}, League: "NHL", LogoCode: "det"},
		{Name: "Edmonton Oilers", City: "Edmonton", Nickname: "Oilers", Aliases: []string{"EDM"}, League: "NHL", LogoCode: "edm"},
		{Name: "Florida Panthers", City: "Florida", Nickname: "Panthers", Aliases: []string{"FLA"}, League: "NHL", LogoCode: "fla"},
		{Name: "Los Angeles Kings", City: "Los Angeles", Nickname: "Kings", Aliases: []string{"LAK", "LA"}, League: "NHL", LogoCode: "la"},
		{Name: "Minnesota Wild", City: "Minnesota", Nickname: "Wild", Aliases: []string{"MIN"}, League: "NHL", LogoCode: "min"},
		{Name: "Montreal Canadiens", City: "Montreal", Nickname: "Canadiens", Aliases: []string{"MTL", "Habs"}, League: "NHL", LogoCode: "mtl"},
		{Name: "Nashville Predators", City: "Nashville", Nickname: "Predators", Aliases: []string{"NSH", "Preds"}, League: "NHL", LogoCode: "nsh"},
		{Name: "New Jersey Devils", City: "New Jersey", Nickname: "Devils", Aliases: []string{"NJD", "NJ"}, League: "NHL", LogoCode: "nj"},
		{Name: "New York Islanders", City: "New York", Nickname: "Islanders", Aliases: []string{"NYI", "Isles"}, League: "NHL", LogoCode: "nyi"},
		{Name: "New York Rangers", City: "New York", Nickname: "Rangers", Aliases: []string{"NYR"}, League: "NHL", LogoCode: "nyr"},
		{Name: "Ottawa Senators", City: "Ottawa", Nickname: "Senators", Aliases: []string{"OTT", "Sens"}, League: "NHL", LogoCode: "ott"},
		{Name: "Philadelphia Flyers", City: "Philadelphia", Nickname: "Flyers", Aliases: []string{"PHI"}, League: "NHL", LogoCode: "phi"},
		{Name: "Pittsburgh Penguins", City: "Pittsburgh", Nickname: "Penguins", Aliases: []string{"PIT", "Pens"}, League: "NHL", LogoCode: "pit"},
		{Name: "San Jose Sharks", City: "San Jose", Nickname: "Sharks", Aliases: []string{"SJS", "SJ"}, League: "NHL", LogoCode: "sj"},
		{Name: "Seattle Kraken", City: "Seattle", Nickname: "Kraken", Aliases: []string{"SEA"}, League: "NHL", LogoCode: "sea"},
		{Name: "St. Louis Blues", City: "St. Louis", Nickname: "Blues", Aliases: []string{"STL"}, League: "NHL", LogoCode: "stl"},
		{Name: "Tampa Bay Lightning", City: "Tampa Bay", Nickname: "Lightning", Aliases: []string{"TBL", "TB", "Bolts"}, League: "NHL", LogoCode: "tb"},
		{Name: "Toronto Maple Leafs", City: "Toronto", Nickname: "Maple Leafs", Aliases: []string{"TOR", "Leafs"}, League: "NHL", LogoCode: "tor"},
		{Name: "Utah Hockey Club", City: "Utah", Nickname: "Hockey Club", Aliases: []string{"UTA"}, League: "NHL", LogoCode: "uta"},
		{Name: "Vancouver Canucks", City: "Vancouver", Nickname: "Canucks", Aliases: []string{"VAN"}, League: "NHL", LogoCode: "van"},
		{Name: "Vegas Golden Knights", City: "Vegas", Nickname: "Golden Knights", Aliases: []string{"VGK", "Knights"}, League: "NHL", LogoCode: "vgk"},
		{Name: "Washington Capitals", City: "Washington", Nickname: "Capitals", Aliases: []string{"WAS", "WSH", "Caps"}, League: "NHL", LogoCode: "wsh"},
		{Name: "Winnipeg Jets", City: "Winnipeg", Nickname: "Jets", Aliases: []string{"WPG"}, League: "NHL", LogoCode: "wpg"},
	},
	"MLS": {
		{Name: "Atlanta United FC", City: "Atlanta", Nickname: "United", Aliases: []string{"ATL"}, League: "MLS"},
		{Name: "Austin FC", City: "Austin", Nickname: "Austin FC", Aliases: []string{"ATX"}, League: "MLS"},
		{Name: "Charlotte FC", City: "Charlotte", Nickname: "Charlotte FC", Aliases: []string{"CLT"}, League: "MLS"},
		{Name: "Chicago Fire FC", City: "Chicago", Nickname: "Fire", Aliases: []string{"CHI"}, League: "MLS"},
		{Name: "FC Cincinnati", City: "Cincinnati", Nickname: "FC Cincinnati", Aliases: []string{"CIN", "FCC"}, League: "MLS"},
		{Name: "Colorado Rapids", City: "Colorado", Nickname: "Rapids", Aliases: []string{"COL"}, League: "MLS"},
		{Name: "Columbus Crew", City: "Columbus", Nickname: "Crew", Aliases: []string{"CLB"}, League: "MLS"},
		{Name: "D.C. United", City: "D.C.", Nickname: "United", Aliases: []string{"DCU", "DC"}, League: "MLS"},
		{Name: "FC Dallas", City: "Dallas", Nickname: "FC Dallas", Aliases: []string{"DAL", "FCD"}, League: "MLS"},
		{Name: "Houston Dynamo FC", City: "Houston", Nickname: "Dynamo", Aliases: []string{"HOU"}, League: "MLS"},
		{Name: "Sporting Kansas City", City: "Kansas City", Nickname: "Sporting KC", Aliases: []string{"SKC", "KC"}, League: "MLS"},
		{Name: "LA Galaxy", City: "Los Angeles", Nickname: "Galaxy", Aliases: []string{"LAG", "LA"}, League: "MLS"},
		{Name: "Los Angeles FC", City: "Los Angeles", Nickname: "LAFC", Aliases: []string{"LAFC"}, League: "MLS"},
		{Name: "Inter Miami CF", City: "Miami", Nickname: "Inter Miami", Aliases: []string{"MIA", "INT"}, League: "MLS"},
		{Name: "Minnesota United FC", City: "Minnesota", Nickname: "Loons", Aliases: []string{"MIN", "MNUFC"}, League: "MLS"},
		{Name: "CF Montréal", City: "Montréal", Nickname: "CF Montréal", Aliases: []string{"MTL", "Impact"}, League: "MLS"},
		{Name: "Nashville SC", City: "Nashville", Nickname: "Nashville SC", Aliases: []string{"NSH"}, League: "MLS"},
		{Name: "New England Revolution", City: "New England", Nickname: "Revolution", Aliases: []string{"NE", "NEP", "Revs"}, League: "MLS"},
		{Name: "New York City FC", City: "New York", Nickname: "NYCFC", Aliases: []string{"NYC", "NYCFC"}, League: "MLS"},
		{Name: "New York Red Bulls", City: "New York", Nickname: "Red Bulls", Aliases: []string{"NYRB", "NY"}, League: "MLS"},
		{Name: "Orlando City SC", City: "Orlando", Nickname: "Orlando City", Aliases: []string{"ORL", "OCSC"}, League: "MLS"},
		{Name: "Philadelphia Union", City: "Philadelphia", Nickname: "Union", Aliases: []string{"PHI"}, League: "MLS"},
		{Name: "Portland Timbers", City: "Portland", Nickname: "Timbers", Aliases: []string{"POR"}, League: "MLS"},
		{Name: "Real Salt Lake", City: "Salt Lake", Nickname: "Real Salt Lake", Aliases: []string{"RSL"}, League: "MLS"},
		{Name: "San Diego FC", City: "San Diego", Nickname: "San Diego FC", Aliases: []string{"SD"}, League: "MLS"},
		{Name: "San Jose Earthquakes", City: "San Jose", Nickname: "Earthquakes", Aliases: []string{"SJ", "Quakes"}, League: "MLS"},
		{Name: "Seattle Sounders FC", City: "Seattle", Nickname: "Sounders", Aliases: []string{"SEA"}, League: "MLS"},
		{Name: "St. Louis City SC", City: "St. Louis", Nickname: "City SC", Aliases: []string{"STL"}, League: "MLS"},
		{Name: "Toronto FC", City: "Toronto", Nickname: "Toronto FC", Aliases: []string{"TOR", "TFC"}, League: "MLS"},
		{Name: "Vancouver Whitecaps FC", City: "Vancouver", Nickname: "Whitecaps", Aliases: []string{"VAN"}, League: "MLS"},
	},
}

// GetAllLeagues returns a list of all available leagues
func GetAllLeagues() []string {
	return []string{"NFL", "NBA", "MLB", "NHL", "MLS"}
}

// GetTeamsByLeague returns all teams for a given league
func GetTeamsByLeague(league string) []SportsTeam {
	return SportsTeamDB[strings.ToUpper(league)]
}

// Ambiguous nicknames that should NOT be matched alone (used by multiple teams or common words)
var ambiguousNicknames = map[string]bool{
	"bears":     true, // Chicago Bears, but also Hershey Bears (AHL), baby bears, etc.
	"giants":    true, // NY Giants (NFL), SF Giants (MLB)
	"cardinals": true, // Arizona Cardinals (NFL), St. Louis Cardinals (MLB)
	"rangers":   true, // Texas Rangers (MLB), NY Rangers (NHL)
	"kings":     true, // LA Kings (NHL), Sacramento Kings (NBA)
	"panthers":  true, // Carolina Panthers (NFL), Florida Panthers (NHL)
	"jets":      true, // NY Jets (NFL), Winnipeg Jets (NHL)
	"heat":      true, // Miami Heat, common word
	"magic":     true, // Orlando Magic, common word
	"jazz":      true, // Utah Jazz, common word
	"thunder":   true, // OKC Thunder, common word
	"wild":      true, // Minnesota Wild, common word
	"fire":      true, // Chicago Fire FC, common word
	"united":    true, // Multiple MLS teams, common word
	"fc":        true, // Common suffix
	"stars":     true, // Dallas Stars, common word
	"blues":     true, // St. Louis Blues, common word
	"reds":      true, // Cincinnati Reds, common word
	"twins":     true, // Minnesota Twins, common word
	"rays":      true, // Tampa Bay Rays, common word
}

// FindTeamInText searches for any team name/alias in the given text
// Returns the matched teams with their leagues
func FindTeamInText(text string) []SportsTeam {
	if text == "" {
		return nil
	}

	textLower := strings.ToLower(text)
	var matches []SportsTeam
	seen := make(map[string]bool) // Avoid duplicates

	for _, teams := range SportsTeamDB {
		for _, team := range teams {
			if seen[team.Name] {
				continue
			}

			// Check full name (most reliable)
			if strings.Contains(textLower, strings.ToLower(team.Name)) {
				matches = append(matches, team)
				seen[team.Name] = true
				continue
			}

			// Check city + nickname (e.g., "Chicago Bears")
			cityNickname := strings.ToLower(team.City + " " + team.Nickname)
			if strings.Contains(textLower, cityNickname) {
				matches = append(matches, team)
				seen[team.Name] = true
				continue
			}

			// Only check nickname alone if it's NOT ambiguous
			nickname := strings.ToLower(team.Nickname)
			if !ambiguousNicknames[nickname] && len(nickname) >= 5 {
				if containsWord(textLower, nickname) {
					matches = append(matches, team)
					seen[team.Name] = true
					continue
				}
			}

			// Check specific aliases (like team abbreviations in sports context)
			// Only match longer aliases to avoid false positives
			for _, alias := range team.Aliases {
				aliasLower := strings.ToLower(alias)
				if len(aliasLower) >= 4 && containsWord(textLower, aliasLower) {
					matches = append(matches, team)
					seen[team.Name] = true
					break
				}
			}
		}
	}

	return matches
}

// FindTeamByName finds a team by exact or partial name match
func FindTeamByName(name string) *SportsTeam {
	nameLower := strings.ToLower(strings.TrimSpace(name))

	for _, teams := range SportsTeamDB {
		for i := range teams {
			team := &teams[i]

			// Exact match on full name
			if strings.ToLower(team.Name) == nameLower {
				return team
			}

			// Match on nickname
			if strings.ToLower(team.Nickname) == nameLower {
				return team
			}

			// Match on city + nickname
			cityNickname := strings.ToLower(team.City + " " + team.Nickname)
			if cityNickname == nameLower {
				return team
			}

			// Match on alias
			for _, alias := range team.Aliases {
				if strings.ToLower(alias) == nameLower {
					return team
				}
			}
		}
	}

	return nil
}

// SearchTeams searches for teams matching the query
func SearchTeams(query string) []SportsTeam {
	if query == "" {
		return nil
	}

	queryLower := strings.ToLower(strings.TrimSpace(query))
	var matches []SportsTeam

	for _, teams := range SportsTeamDB {
		for _, team := range teams {
			// Check name contains query
			if strings.Contains(strings.ToLower(team.Name), queryLower) {
				matches = append(matches, team)
				continue
			}

			// Check city
			if strings.Contains(strings.ToLower(team.City), queryLower) {
				matches = append(matches, team)
				continue
			}

			// Check nickname
			if strings.Contains(strings.ToLower(team.Nickname), queryLower) {
				matches = append(matches, team)
				continue
			}
		}
	}

	return matches
}

// containsWord checks if text contains word as a whole word (not part of another word)
func containsWord(text, word string) bool {
	if len(word) < 3 {
		// For short words like "NY", require exact word boundary
		words := strings.Fields(text)
		for _, w := range words {
			// Clean punctuation
			cleaned := strings.Trim(w, ".,!?;:()[]{}\"'")
			if cleaned == word {
				return true
			}
		}
		return false
	}

	// For longer words, allow substring match if surrounded by non-letters
	idx := strings.Index(text, word)
	if idx == -1 {
		return false
	}

	// Check character before word
	if idx > 0 {
		before := text[idx-1]
		if isLetter(before) {
			return false
		}
	}

	// Check character after word
	afterIdx := idx + len(word)
	if afterIdx < len(text) {
		after := text[afterIdx]
		if isLetter(after) {
			return false
		}
	}

	return true
}

func isLetter(c byte) bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}
