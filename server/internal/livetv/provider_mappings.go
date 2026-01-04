package livetv

// ProviderMapping maps a provider's channel ID to Gracenote station ID
type ProviderMapping struct {
	StationID string `json:"StationID"`
	Name      string `json:"name"`
	TimeShift string `json:"TimeShift,omitempty"` // Hours offset for time-shifted channels
}

// FuboTVMappings maps FuboTV channel IDs to Gracenote station IDs
// Source: https://gitlab.com/vlc-bridge-fubo-test/vlc-bridge-fubo/-/blob/main/fubo-gracenote-default.json
var FuboTVMappings = map[string]ProviderMapping{
	"44631":      {StationID: "11534", Name: "ABC - WTHM"},
	"127957":     {StationID: "113380", Name: "ABC News Live - ABCNL"},
	"1263880001": {StationID: "111871", Name: "ACC Network - ACC"},
	"126388":     {StationID: "111871", Name: "ACC Network - ACC"},
	"104589":     {StationID: "120551", Name: "AccuWeather - ACUWTHH"},
	"139932":     {StationID: "125196", Name: "ACL Cornhole TV - CRNHOLE"},
	"123265":     {StationID: "109016", Name: "africanews - AFNEWS"},
	"44264":      {StationID: "65596", Name: "Altitude Sports - ALTSPRT"},
	"66322":      {StationID: "56256", Name: "Altitude Sports Overflow - ALTS2"},
	"90696":      {StationID: "18284", Name: "American Heroes Channel - AHCHD"},
	"67512":      {StationID: "57394", Name: "Animal Planet - APLHD"},
	"80124":      {StationID: "68785", Name: "Animal Planet - APLHDP"},
	"136322":     {StationID: "136199", Name: "Arizona Diamondbacks"},
	"141981":     {StationID: "127174", Name: "At Home with Family Handyman - ATHFHM"},
	"137849":     {StationID: "123156", Name: "AXS TV NOW - AXSTNST"},
	"88749":      {StationID: "76950", Name: "beIN SPORTS - BEIN1HD"},
	"105107":     {StationID: "92443", Name: "beIN SPORTS 4 - BEIN4"},
	"105103":     {StationID: "92439", Name: "beIN SPORTS 5 - BEIN5"},
	"105101":     {StationID: "92437", Name: "beIN SPORTS 6 - BEIN6"},
	"105102":     {StationID: "92438", Name: "beIN SPORTS 7 - BEIN7"},
	"105100":     {StationID: "92436", Name: "beIN SPORTS 8 - BEIN8"},
	"88754":      {StationID: "76943", Name: "beIN SPORTS En Espanol - BEIN2HD"},
	"127712":     {StationID: "120375", Name: "beIN SPORTS Xtra - BEINXTRA"},
	"134321":     {StationID: "119661", Name: "beIN SPORTS Xtra En Espanol - BEIXE"},
	"119429":     {StationID: "92442", Name: "beIN SPORTS 3 - BEINSP3"},
	"73973":      {StationID: "63236", Name: "BET - BETHD"},
	"75572":      {StationID: "64673", Name: "BET - BETHDP"},
	"73952":      {StationID: "63220", Name: "BET Her - BHERHD"},
	"71605":      {StationID: "58321", Name: "Big Ten Network - BTN"},
	"84686":      {StationID: "73115", Name: "Big Ten Network Alternate 2 - BTN2"},
	"94683":      {StationID: "82572", Name: "Big Ten Network Alternate 3 - BTN3"},
	"94684":      {StationID: "82573", Name: "Big Ten Network Alternate 4 - BTN4"},
	"135138":     {StationID: "120469", Name: "Billiard TV - BILSTR"},
	"138563":     {StationID: "123870", Name: "Bloomberg Originals - QUICKTK"},
	"83287":      {StationID: "71799", Name: "Bloomberg Television - BLOOM"},
	"832870001":  {StationID: "53168", Name: "Bloomberg Television - BLOOMBR"},
	"139931":     {StationID: "125195", Name: "Boxing TV - BOXING"},
	"68797":      {StationID: "58625", Name: "Bravo - BVO"},
	"85639":      {StationID: "73994", Name: "Bravo - BVOW"},
	"118793":     {StationID: "104846", Name: "CBS News - CBSN"},
	"69495":      {StationID: "59250", Name: "CBS Sports Network - CBSSN"},
	"114796":     {StationID: "107241", Name: "Cheddar News - CHEDDAR"},
	"130949":     {StationID: "116338", Name: "Circle Country - XCIRCLE"},
	"124684":     {StationID: "110289", Name: "CleoTV - CLEOHD"},
	"69697":      {StationID: "59440", Name: "CMT - CMTVHD"},
	"68971":      {StationID: "58780", Name: "CNBC - CNBC"},
	"73033":      {StationID: "62420", Name: "Comedy Central - CCHD"},
	"75486":      {StationID: "64599", Name: "Comedy Central - CCHDP"},
	"130049":     {StationID: "115447", Name: "Comedy Dynamics - COMCLN"},
	"110223":     {StationID: "97051", Name: "Comet - COMET"},
	"79312":      {StationID: "68065", Name: "Cooking Channel - COOKHD"},
	"135843":     {StationID: "121166", Name: "Crackle - CRACKLEHD"},
	"125430":     {StationID: "110951", Name: "Curiosity Channel - CSTREAM"},
	"120762":     {StationID: "112158", Name: "Dabl - DABLPHD"},
	"143350":     {StationID: "128542", Name: "Dark Matter - DMTV"},
	"70835":      {StationID: "60468", Name: "Destination America - DESTHD"},
	"67013":      {StationID: "56905", Name: "Discovery - DSCHD"},
	"92410":      {StationID: "80399", Name: "Discovery - DSCHDP"},
	"78969":      {StationID: "67749", Name: "Discovery Family Channel - DFCHD"},
	"104830":     {StationID: "92204", Name: "Discovery Life - DLCHD"},
	"10171":      {StationID: "59684", Name: "Disney Channel - DISN"},
	"74063":      {StationID: "63320", Name: "Disney Channel - DISNHDP"},
	"86580":      {StationID: "74885", Name: "Disney Junior - DJCHHD"},
	"86703":      {StationID: "75004", Name: "Disney Junior - DJCHHDP"},
	"70322":      {StationID: "60006", Name: "Disney XD - DXDHD"},
	"74065":      {StationID: "63322", Name: "Disney XD - DXDHDP"},
	"124902":     {StationID: "110480", Name: "Dove Channel - DOVESTR"},
	"127430":     {StationID: "112881", Name: "DUST - DUST"},
	"72360":      {StationID: "61812", Name: "E! - EE"},
	"104147":     {StationID: "91579", Name: "E! - EW"},
	"10179":      {StationID: "32645", Name: "ESPN - ESPN"},
	"83407":      {StationID: "71914", Name: "ESPN Deportes - ESPNDHD"},
	"71094":      {StationID: "60696", Name: "ESPN U - ESPNUHD"},
	"12444":      {StationID: "45507", Name: "ESPN2 - ESPN2"},
	"16485":      {StationID: "59976", Name: "ESPNEWS - ESPNEWS"},
	"76019":      {StationID: "65064", Name: "ESTRELLA - ESTRLLA"},
	"135881":     {StationID: "133321", Name: "Fail Army - FLARMY"},
	"50791":      {StationID: "50747", Name: "Food Network - FOODHD"},
	"94206":      {StationID: "82119", Name: "Food Network - FOODPHD"},
	"10422":      {StationID: "21319", Name: "FOX - KDVR"},
	"111886":     {StationID: "98443", Name: "FOX - KRQEDT2"},
	"123918":     {StationID: "170877", Name: "FOX 4K - FOX4K"},
	"68900":      {StationID: "58718", Name: "FOX Business Network - FBNHD"},
	"133875":     {StationID: "119219", Name: "FOX LiveNOW - LIVENOW"},
	"70522":      {StationID: "60179", Name: "FOX News Channel - FNCHD"},
	"77985":      {StationID: "66880", Name: "Fox Soccer Plus - FSCPLHD"},
	"133868":     {StationID: "119212", Name: "FOX Soul - FOXSOUL"},
	"94653":      {StationID: "82547", Name: "FOX Sports 1 - FS1"},
	"69553":      {StationID: "59305", Name: "FOX Sports 2 - FS2"},
	"135986":     {StationID: "121307", Name: "FOX Weather - FWX"},
	"69896":      {StationID: "59615", Name: "Freeform - FREFMHD"},
	"74067":      {StationID: "63324", Name: "Freeform - FRFMHDP"},
	"123917":     {StationID: "109605", Name: "FS1 4K - FFS14K"},
	"131921":     {StationID: "117288", Name: "Fubo Latino Network - FUBOLN"},
	"131622":     {StationID: "116999", Name: "fubo Movie Network - FMOVTV"},
	"36500000":   {StationID: "116999", Name: "Fubo Movies - FMOVIEUS"},
	"120123":     {StationID: "106100", Name: "fubo Sports Network - FNETTV"},
	"1238520002": {StationID: "125447", Name: "fubo Sports Network 2 - FNETTV2"},
	"1238520004": {StationID: "125466", Name: "fubo Sports Network 3 - FNETTV3"},
	"1238520014": {StationID: "125457", Name: "fubo Sports Network 4 - FNETTV4"},
	"1238520015": {StationID: "125465", Name: "fubo Sports Network 5 - FNETTV5"},
	"1238520018": {StationID: "125453", Name: "fubo Sports Network 6 - FNETTV6"},
	"1238520019": {StationID: "125450", Name: "fubo Sports Network 7 - FNETTV7"},
	"1238520112": {StationID: "158971", Name: "fubo Sports Network 9 - FNETTV9"},
	"1238520113": {StationID: "158972", Name: "fubo Sports Network 10 - FNETTV10"},
	"1238520114": {StationID: "158973", Name: "fubo Sports Network 11 - FNETTV11"},
	"139008":     {StationID: "124313", Name: "FUEL TV - FUELFUB"},
	"68746":      {StationID: "58574", Name: "FX - FXHD"},
	"70111":      {StationID: "59814", Name: "FX - FXPHD"},
	"81675":      {StationID: "70253", Name: "FXM - FXMHD"},
	"77475":      {StationID: "66379", Name: "FXX - FXXHD"},
	"94682":      {StationID: "82571", Name: "FXX - FXXPHD"},
	"79698":      {StationID: "68367", Name: "Galavision - GALAHD"},
	"108539":     {StationID: "89098", Name: "GAME+ - FNTSYUH"},
	"94674":      {StationID: "82563", Name: "getTV - GETTV"},
	"103351":     {StationID: "90858", Name: "Great American Faith & Living - GACLHD"},
	"95030":      {StationID: "82892", Name: "Great American Family - GAC"},
	"80167":      {StationID: "68827", Name: "GSN - GSNHD"},
	"125634":     {StationID: "111140", Name: "Gusto - GUSTOTV"},
	"77355":      {StationID: "66268", Name: "Hallmark Channel - HALLHD"},
	"119725":     {StationID: "105723", Name: "Hallmark Drama - HALLDR"},
	"46730":      {StationID: "46710", Name: "Hallmark Movies & Mysteries - HMMHD"},
	"49830":      {StationID: "49788", Name: "HGTV - HGTVD"},
	"99621":      {StationID: "87317", Name: "HGTV - HGTVPHD"},
	"134964":     {StationID: "105893", Name: "Horse & Country - HORACOU", TimeShift: "-2"},
	"116116":     {StationID: "102309", Name: "i24NEWS - I24NEHD"},
	"136673":     {StationID: "121991", Name: "IMPACT! Wrestling - IMPACTW"},
	"144256":     {StationID: "129479", Name: "INFAST - INFAST"},
	"11066":      {StationID: "82773", Name: "INSP - INSP"},
	"76327":      {StationID: "65342", Name: "Investigation Discovery - IDHD"},
	"144254":     {StationID: "112796", Name: "INWONDER - INSIWON"},
	"18633":      {StationID: "122912", Name: "ION - ION"},
	"133890":     {StationID: "119234", Name: "Judge Nosey - RLNOSEY"},
	"90742":      {StationID: "78850", Name: "Justice Central - JUST"},
	"131621":     {StationID: "116998", Name: "Lacrosse Sports Network - LSN"},
	"113594":     {StationID: "99988", Name: "Local Now - LOCALNOW"},
	"133606":     {StationID: "118952", Name: "Localish - LOCALSH"},
	"110114":     {StationID: "96971", Name: "Logo - LOGOHD"},
	"134814":     {StationID: "119209", Name: "Magellan - MAGUTC1"},
	"78575":      {StationID: "67375", Name: "Magnolia Network - DIYHD"},
	"1283550001": {StationID: "113768", Name: "Marquee Sports Network - MARQN"},
	"76716":      {StationID: "65687", Name: "MGM+ - EPIXHD"},
	"79162":      {StationID: "67929", Name: "MGM+ Hits - EPIX2HD"},
	"85722":      {StationID: "74073", Name: "MGM+ Marquee - EPIXHIT"},
	"72650":      {StationID: "62081", Name: "MLB Network - MLBHD"},
	"86927":      {StationID: "75220", Name: "MLB Strikezone - MLBNSZ"},
	"81130":      {StationID: "69734", Name: "Monumental Sports Network 2 - MNMT2HD"},
	"139933":     {StationID: "125197", Name: "MotoAmerica TV - MOTO"},
	"75083":      {StationID: "64241", Name: "MSNBC - MSNBC"},
	"71401":      {StationID: "60964", Name: "MTV - MTVHD"},
	"75524":      {StationID: "64630", Name: "MTV - MTVPHD"},
	"104879":     {StationID: "22561", Name: "MTV Classic - MTVCLHD"},
	"49175":      {StationID: "49141", Name: "MTV Live - MTVLIVE"},
	"86781":      {StationID: "75077", Name: "MTV2 - MTV2HD"},
	"44229":      {StationID: "44228", Name: "MTVU - MTVU"},
	"49472":      {StationID: "49438", Name: "National Geographic - NGCHD"},
	"83074":      {StationID: "71601", Name: "National Geographic - NGCPHD"},
	"78529":      {StationID: "67331", Name: "National Geographic Wild - NGWIHD"},
	"45537":      {StationID: "45526", Name: "NBA TV - NBATV"},
	"21298":      {StationID: "91638", Name: "NBC - KUSA"},
	"128770":     {StationID: "114174", Name: "NBC News NOW - NBCNN"},
	"123916":     {StationID: "109604", Name: "NBC Sports 4K - FNBCS4K"},
	"1137270001": {StationID: "109604", Name: "NBC Sports 4K - FNBCS4K"},
	"73858":      {StationID: "63138", Name: "NBC Sports Bay Area - NBCSBAH"},
	"114968":     {StationID: "101261", Name: "NBC Sports Bay Area Plus - NBSBA2H"},
	"45551":      {StationID: "45540", Name: "NBC Sports California - NBSCAHD"},
	"107332":     {StationID: "92393", Name: "NBC Sports California Plus - NBCSCAH"},
	"125380":     {StationID: "110904", Name: "NBC Sports California Plus 3 - NBCSCX3"},
	"109261":     {StationID: "17596", Name: "NBC Sports Philadelphia - NBCSPA"},
	"101207":     {StationID: "88829", Name: "NBC Sports Philadelphia Plus - NBSPPHD"},
	"104468":     {StationID: "102959", Name: "NBC Universo - UNIV"},
	"104156":     {StationID: "91588", Name: "NBC Universo - UNIVE"},
	"128875":     {StationID: "114278", Name: "NBCLX - LX"},
	"131568":     {StationID: "116946", Name: "News 12 New York - N12NY"},
	"103625":     {StationID: "91096", Name: "NewsNation - WGNA"},
	"124843":     {StationID: "110428", Name: "NewsNet - NEWSNT"},
	"99285":      {StationID: "87000", Name: "Next Level Sports - OWSPNHD"},
	"45409":      {StationID: "45399", Name: "NFL Network - NFLHD"},
	"75963":      {StationID: "65025", Name: "NFL RedZone - NFLNRZD"},
	"68871":      {StationID: "58690", Name: "NHL Network - NHLNET"},
	"99645":      {StationID: "87339", Name: "Nick Jr. - NICJPHD"},
	"94767":      {StationID: "82649", Name: "Nick Jr. - NICJRHD"},
	"69687":      {StationID: "59432", Name: "Nickelodeon - NIKHD"},
	"75478":      {StationID: "64591", Name: "Nickelodeon - NIKPHD"},
	"30420":      {StationID: "82654", Name: "Nicktoons - NIKTON"},
	"133889":     {StationID: "119233", Name: "Nosey - NOSEY"},
	"139513":     {StationID: "124817", Name: "Origin Sports Network - ORIG"},
	"128911":     {StationID: "68295", Name: "Outside - OTVSTR"},
	"81808":      {StationID: "70388", Name: "OWN - OWNHD"},
	"81949":      {StationID: "70522", Name: "Oxygen True Crime - OXG"},
	"85680":      {StationID: "74032", Name: "Oxygen True Crime - OXGW"},
	"881660001":  {StationID: "76376", Name: "Pac-12 Arizona - P12AZHD"},
	"881670001":  {StationID: "76377", Name: "Pac-12 Bay Area - P12BAHD"},
	"139952":     {StationID: "125214", Name: "Pac-12 Insider - P12I"},
	"881710001":  {StationID: "76381", Name: "Pac-12 Los Angeles - P12LAHD"},
	"88170":      {StationID: "76380", Name: "Pac-12 Mountain - P12MTHD"},
	"881700001":  {StationID: "76380", Name: "Pac-12 Mountain - P12MTHD"},
	"88172":      {StationID: "76382", Name: "Pac-12 Network - PAC12HD"},
	"881680001":  {StationID: "76378", Name: "Pac-12 Oregon - P12ORHD"},
	"881690001":  {StationID: "76379", Name: "Pac-12 Washington - P12WAHD"},
	"69429":      {StationID: "59186", Name: "Paramount Network - PARHD"},
	"137212":     {StationID: "122524", Name: "People Are Awesome - PAAFRUS"},
	"138963":     {StationID: "124268", Name: "PokerGO - PKGFAST"},
	"80136":      {StationID: "68796", Name: "POP - POP"},
	"135844":     {StationID: "121167", Name: "Popcornflix - POPCORNFLIXHD"},
	"70566":      {StationID: "60222", Name: "QVC - QVCHD"},
	"139326":     {StationID: "124630", Name: "Racing America - RA"},
	"135874":     {StationID: "121197", Name: "Real Madrid TV - RMADUSHD"},
	"134013":     {StationID: "119355", Name: "RetroCrush - RRCRUSH"},
	"128187":     {StationID: "113603", Name: "Revry - REVRY"},
	"130712":     {StationID: "116102", Name: "Revry News - RVRYNWS"},
	"76835":      {StationID: "11063", Name: "ROOT Sports Northwest (Alt.) - RTN1"},
	"71543":      {StationID: "61090", Name: "ROOT Sports Northwest - RTNWHD"},
	"136101":     {StationID: "121422", Name: "ROOT Sports Northwest PLUS - RTNW3"},
	"136288":     {StationID: "136227", Name: "San Diego Padres"},
	"67508":      {StationID: "57390", Name: "Science - SCIHD"},
	"120010":     {StationID: "96827", Name: "Scripps News - NEWSYST"},
	"1021370001": {StationID: "89714", Name: "SEC Network - SECH"},
	"68703":      {StationID: "58532", Name: "Smithsonian Channel - SMITH_HD"},
	"94823":      {StationID: "82695", Name: "Smithsonian Channel - SMITHP_HD"},
	"80496":      {StationID: "69091", Name: "Sony Movie Channel - SONYHD"},
	"127275":     {StationID: "112732", Name: "Sportsgrid - SPOGRID"},
	"49925":      {StationID: "49882", Name: "SportsNet Pittsburgh - SNPTHD"},
	"143989":     {StationID: "129212", Name: "SportStak - SPRTSTK"},
	"118905":     {StationID: "104950", Name: "Stadium - STADIUM"},
	"109524":     {StationID: "96469", Name: "Stadium 1 - STAD1"},
	"109621":     {StationID: "96550", Name: "Stadium 2 - STAD2"},
	"109622":     {StationID: "96551", Name: "Stadium 3 - STAD3"},
	"122695":     {StationID: "109454", Name: "Start TV - STRTD"},
	"137124":     {StationID: "122436", Name: "Swerve Combat - SWSPRTS"},
	"68795":      {StationID: "58623", Name: "SYFY - SYFY"},
	"76634":      {StationID: "65626", Name: "SYFY - SYFYW"},
	"121191":     {StationID: "107076", Name: "Tastemade - TASTE"},
	"139922":     {StationID: "125187", Name: "Tastemade Home - TMHOME"},
	"135019":     {StationID: "120351", Name: "Tastemade Travel - TMTRAVEL"},
	"110217":     {StationID: "97047", Name: "TeenNick - TNCKHD"},
	"54539":      {StationID: "54424", Name: "Telemundo - KDEN"},
	"70668":      {StationID: "60316", Name: "Tennis Channel - TENISHD"},
	"141477":     {StationID: "126670", Name: "TG Jr - TGJR"},
	"143912":     {StationID: "129135", Name: "The Big Dish - BIGDISH"},
	"1144910001": {StationID: "114491", Name: "The Bob Ross Channel - TBRCSTR"},
	"132722":     {StationID: "118087", Name: "The Design Network - TDN"},
	"104213":     {StationID: "91640", Name: "The Fight Network - FNHD"},
	"72411":      {StationID: "61854", Name: "The Golf Channel - GLFC"},
	"80467":      {StationID: "69101", Name: "GolTV (English) - GOLTVEH"},
	"135842":     {StationID: "110356", Name: "The Pet Collective - PETCOLL"},
	"69008":      {StationID: "58812", Name: "The Weather Channel - WEATHHD"},
	"121623":     {StationID: "107478", Name: "The Young Turks - TYT"},
	"137369":     {StationID: "122679", Name: "Ticker NEWS - TICKER"},
	"67509":      {StationID: "57391", Name: "TLC - TLCHD"},
	"91887":      {StationID: "79911", Name: "TLC - TLCPHD"},
	"141441":     {StationID: "126634", Name: "Toon Goggles - TG"},
	"69551":      {StationID: "59303", Name: "Travel Channel - TRAVHD"},
	"75410":      {StationID: "50000", Name: "Travel Channel - TRAVPHD"},
	"88839":      {StationID: "77033", Name: "TUDN - UDNHD"},
	"126876":     {StationID: "112349", Name: "TUDNxtra 1 - TUDNX1"},
	"126889":     {StationID: "112362", Name: "TUDNxtra 10 - TUDNX10"},
	"126890":     {StationID: "112363", Name: "TUDNxtra 11 - TUDNX11"},
	"126878":     {StationID: "112351", Name: "TUDNxtra 2 - TUDNX2"},
	"126879":     {StationID: "112352", Name: "TUDNxtra 3 - TUDNX3"},
	"126881":     {StationID: "112354", Name: "TUDNxtra 4 - TUDNX4"},
	"126882":     {StationID: "112355", Name: "TUDNxtra 5 - TUDNX5"},
	"126883":     {StationID: "112356", Name: "TUDNxtra 6 - TUDNX6"},
	"126884":     {StationID: "112357", Name: "TUDNxtra 7 - TUDNX7"},
	"126885":     {StationID: "112358", Name: "TUDNxtra 8 - TUDNX8"},
	"126888":     {StationID: "112361", Name: "TUDNxtra 9 - TUDNX9"},
	"85788":      {StationID: "26046", Name: "TV Land - TVLDPHD"},
	"85147":      {StationID: "73541", Name: "TV Land - TVLNDHD"},
	"105592":     {StationID: "62043", Name: "TyC Sports International - TYCINTL"},
	"143825":     {StationID: "129048", Name: "UNBEATEN - UNBEATEN"},
	"87146":      {StationID: "32697", Name: "UniMas - KELVLP"},
	"855130001":  {StationID: "73882", Name: "UniMas - UNIMHD"},
	"81646":      {StationID: "70225", Name: "Universal Kids - SPR"},
	"74568":      {StationID: "63776", Name: "Univision - KLUZDT"},
	"792940001":  {StationID: "68049", Name: "Univision - UNIHD"},
	"68602":      {StationID: "58452", Name: "USA Network - USAN"},
	"85678":      {StationID: "74030", Name: "USA Network - USANW"},
	"556490001":  {StationID: "100592", Name: "Vegas Golden Knights"},
	"70365":      {StationID: "60046", Name: "VH1 - VH1HD"},
	"75529":      {StationID: "64634", Name: "VH1 - VH1PHD"},
	"141948":     {StationID: "127141", Name: "WeatherSpy - WTHRSPY"},
	"139332":     {StationID: "124636", Name: "Women's Sports Network - WSN"},
	"138625":     {StationID: "125051", Name: "World Poker Tour - WPTAMA"},
	"126463":     {StationID: "111945", Name: "Zona Futbol - ZONFUT"},
	"127032":     {StationID: "112496", Name: "INTROUBLE - INSITRO"},
	"74861":      {StationID: "64046", Name: "World Fishing Network - WFNUSHD"},
	"77398":      {StationID: "66310", Name: "The Sportsman Channel - SPMNHD"},
	"71484":      {StationID: "61036", Name: "MAV TV - MAVTVHD"},
	"136103":     {StationID: "121424", Name: "Waypoint TV - WYPOINT"},
	"128846":     {StationID: "55597", Name: "NBA League Pass 1 HD - TMHD1"},
	"128831":     {StationID: "72809", Name: "NBA League Pass 2 HD - TMHD2"},
	"128833":     {StationID: "72831", Name: "NBA League Pass 3 HD - TMHD3"},
	"128835":     {StationID: "72832", Name: "NBA League Pass 4 HD - TMHD4"},
	"128836":     {StationID: "72833", Name: "NBA League Pass 5 HD - TMHD5"},
	"128839":     {StationID: "72831", Name: "NBA League Pass 6 HD - TMHD6"},
	"128840":     {StationID: "72835", Name: "NBA League Pass 7 HD - TMHD7"},
	"128842":     {StationID: "72836", Name: "NBA League Pass 8 HD - TMHD8"},
	"128844":     {StationID: "72837", Name: "NBA League Pass 9 HD - TMHD9"},
	"128845":     {StationID: "102709", Name: "NBA League Pass 10 HD - TMHD10"},
	"46288":      {StationID: "30017", Name: "Yes Network - YES"},
	"134109":     {StationID: "134109", Name: "Always Funny - ALWFV"},
	"54552":      {StationID: "54437", Name: "Telemundo - WNJU"},
	"102430":     {StationID: "78851", Name: "Cozi TV - COZITV"},
	"77366":      {StationID: "11000", Name: "New England Cable News - NECN"},
	"35220000":   {StationID: "159918", Name: "BKFCTV - BKFCTV"},
	"35930000":   {StationID: "167129", Name: "Crime Time - FUBOCRM"},
	"34870000":   {StationID: "159241", Name: "Love Bites - FUBOXO"},
	"34880000":   {StationID: "159240", Name: "Man Cave Movies - FUBOMC"},
	"35960000":   {StationID: "167195", Name: "Terrified - FUBOTER"},
	"12345001":   {StationID: "157823", Name: "WNBA on ION - WNBAOU1"},
	"12345002":   {StationID: "157824", Name: "WNBA on ION - WNBAOU2"},
	"12345003":   {StationID: "157825", Name: "WNBA on ION - WNBAOU3"},
	"129307":     {StationID: "53424", Name: "NFL Network Alternate - NFLALT2"},
}

// LookupFuboTVMapping looks up a Gracenote station ID for a FuboTV channel
// Returns the mapping and true if found, nil and false otherwise
func LookupFuboTVMapping(channelID string) (*ProviderMapping, bool) {
	if mapping, ok := FuboTVMappings[channelID]; ok {
		return &mapping, true
	}
	return nil, false
}

// LookupByCallSign searches for a mapping by call sign (e.g., "ESPN", "FNCHD")
func LookupByCallSign(callSign string) (*ProviderMapping, string, bool) {
	for id, mapping := range FuboTVMappings {
		// Check if call sign is in the name (format: "Channel Name - CALLSIGN")
		if len(mapping.Name) > 0 {
			// Extract call sign from name
			parts := splitLast(mapping.Name, " - ")
			if len(parts) == 2 && equalsIgnoreCase(parts[1], callSign) {
				return &mapping, id, true
			}
		}
	}
	return nil, "", false
}

// LookupByName searches for a mapping by channel name (fuzzy match)
func LookupByName(name string) (*ProviderMapping, string, bool) {
	nameLower := toLower(name)
	for id, mapping := range FuboTVMappings {
		// Check if name contains the search term or vice versa
		mappingNameLower := toLower(mapping.Name)
		if contains(mappingNameLower, nameLower) || contains(nameLower, mappingNameLower) {
			return &mapping, id, true
		}
	}
	return nil, "", false
}

// Helper functions
func splitLast(s, sep string) []string {
	idx := -1
	for i := len(s) - len(sep); i >= 0; i-- {
		if s[i:i+len(sep)] == sep {
			idx = i
			break
		}
	}
	if idx == -1 {
		return []string{s}
	}
	return []string{s[:idx], s[idx+len(sep):]}
}

func equalsIgnoreCase(a, b string) bool {
	return toLower(a) == toLower(b)
}

func toLower(s string) string {
	result := make([]byte, len(s))
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c >= 'A' && c <= 'Z' {
			result[i] = c + 32
		} else {
			result[i] = c
		}
	}
	return string(result)
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(substr) == 0 ||
		(len(s) > 0 && findSubstring(s, substr) >= 0))
}

func findSubstring(s, substr string) int {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return i
		}
	}
	return -1
}
