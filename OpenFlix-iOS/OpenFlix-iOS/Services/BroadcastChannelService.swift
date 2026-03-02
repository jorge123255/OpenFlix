import Foundation

// MARK: - Broadcast Channel Service
// Maps ESPN/TNT/ABC broadcast names to actual channels in our lineup

@MainActor
class BroadcastChannelService: ObservableObject {
    static let shared = BroadcastChannelService()
    
    private let liveTVRepo = LiveTVRepository()
    @Published var channels: [Channel] = []
    @Published var isLoaded = false
    
    // Common broadcast network name variations
    private let broadcastMappings: [String: [String]] = [
        "ESPN": ["ESPN", "ESPN HD", "ESPN US", "ESPNUS"],
        "ESPN2": ["ESPN2", "ESPN 2", "ESPN2 HD"],
        "ESPN3": ["ESPN3", "ESPN 3", "ESPN+"],
        "ESPNU": ["ESPNU", "ESPN U"],
        "TNT": ["TNT", "TNT HD", "TNT US"],
        "TBS": ["TBS", "TBS HD"],
        "ABC": ["ABC", "ABC HD", "WABC", "KABC"],
        "NBC": ["NBC", "NBC HD", "WNBC", "KNBC", "NBC Sports"],
        "CBS": ["CBS", "CBS HD", "WCBS", "KCBS"],
        "FOX": ["FOX", "FOX HD", "WNYW", "FOX Sports"],
        "FS1": ["FS1", "FOX Sports 1", "FS1 HD"],
        "FS2": ["FS2", "FOX Sports 2"],
        "NBCSN": ["NBCSN", "NBC Sports Network", "NBC Sports"],
        "USA": ["USA", "USA Network", "USA HD"],
        "NFL Network": ["NFL Network", "NFL", "NFLN"],
        "NBA TV": ["NBA TV", "NBATV", "NBA"],
        "MLB Network": ["MLB Network", "MLBN", "MLB"],
        "NHL Network": ["NHL Network", "NHLN", "NHL"],
        "Peacock": ["Peacock", "NBC Peacock"],
        "Prime Video": ["Prime Video", "Amazon Prime"],
        "Apple TV+": ["Apple TV+", "Apple TV"],
        "TUDN": ["TUDN", "Univision Deportes"],
        "BTN": ["BTN", "Big Ten Network"],
        "SEC Network": ["SEC Network", "SECN"],
        "ACC Network": ["ACC Network", "ACCN"]
    ]
    
    init() {
        // Channels will be loaded on first access via loadChannels()
    }
    
    func loadChannels() async {
        do {
            try await liveTVRepo.loadChannels()
            self.channels = liveTVRepo.channels
            self.isLoaded = true
        } catch {
            print("BroadcastChannelService: Failed to load channels: \(error)")
        }
    }
    
    // Find a channel that matches the broadcast name
    func findChannel(forBroadcast broadcast: String?) -> Channel? {
        guard let broadcast = broadcast?.trimmingCharacters(in: .whitespaces), !broadcast.isEmpty else {
            return nil
        }
        
        // Get all possible variations of this broadcast name
        let variations = broadcastMappings[broadcast] ?? [broadcast]
        
        // Search through our channels
        for variation in variations {
            let variationLower = variation.lowercased()
            
            // Try exact match first
            if let channel = channels.first(where: { $0.name.lowercased() == variationLower }) {
                return channel
            }
            
            // Try contains match
            if let channel = channels.first(where: { $0.name.lowercased().contains(variationLower) }) {
                return channel
            }
        }
        
        // Try direct partial match on original broadcast name
        let broadcastLower = broadcast.lowercased()
        if let channel = channels.first(where: { $0.name.lowercased().contains(broadcastLower) }) {
            return channel
        }
        
        return nil
    }
    
    // Check if we have a specific broadcast channel
    func hasChannel(forBroadcast broadcast: String?) -> Bool {
        findChannel(forBroadcast: broadcast) != nil
    }
    
    // Get display info for a broadcast
    func channelInfo(forBroadcast broadcast: String?) -> (channel: Channel, displayName: String)? {
        guard let channel = findChannel(forBroadcast: broadcast) else { return nil }
        let displayName = channel.number != nil ? "Ch. \(channel.number!) \(channel.name)" : channel.name
        return (channel, displayName)
    }
}
