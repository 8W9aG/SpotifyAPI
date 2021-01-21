import Foundation

/**
 A Spotify [play history object][1].
 
 Contains information about a recently played track,
 including the time it was played, and the context it was played in.
 
 [1]: https://developer.spotify.com/documentation/web-api/reference/#object-playhistoryobject
 */
public struct PlayHistory: Hashable {
    
    /// The track that the user listened to (simplified version).
    public let track: Track
    
    /// The date and time the track was played.
    public let playedAt: Date
    
    /// The context the track was played from, such as
    /// an album, artist, or playlist.
    public let context: SpotifyContext?
    
    /**
     A Spotify [play history object][1].
     
     - Parameters:
       - track: The track that the user listened to (simplified version).
       - playedAt: The date and time the track was played.
       - context: The context the track was played from, such as an album, artist,
             or playlist.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/#object-playhistoryobject
     */
    public init(
        track: Track,
        playedAt: Date,
        context: SpotifyContext?
    ) {
        self.track = track
        self.playedAt = playedAt
        self.context = context
    }
    
}

extension PlayHistory: Codable {
    
    /// :nodoc:
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.track = try container.decode(Track.self, forKey: .track)
        self.playedAt = try container.decodeSpotifyTimestamp(
            forKey: .playedAt
        )
        self.context = try container.decodeIfPresent(
            SpotifyContext.self, forKey: .context
        )

    }
    
    /// :nodoc:
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(
            self.track, forKey: .track
        )
        try container.encodeSpotifyTimestamp(
            self.playedAt, forKey: .playedAt
        )
        try container.encodeIfPresent(
            self.context, forKey: .context
        )
        
    }
    
    
    /// :nodoc:
    public enum CodingKeys: String, CodingKey {
        case track
        case playedAt = "played_at"
        case context
    }
    
}

