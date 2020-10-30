import Foundation

/**
 Contains details about a playlist. Used in the body of
 `changePlaylistDetails(_:to:)` and `createPlaylist(for:_:)`.
 
 All of the properties are optional. The value of each non-`nil` property
 will be used to update the details of the playlist.
 
 Contains the following properties:
 
 * name: The new name for the playlist.
 * isPublic: If `true` the playlist will be public;
       if `false` it will be private. Default: `true`.
 * collaborative: If `true`, the playlist will become collaborative
       and other users will be able to modify the playlist in their
       Spotify client. Default: `false`. **Note**: You can only set
       collaborative to `true` on non-public playlists.
 * description: A new playlist description as displayed in
       Spotify Clients and in the Web API.
 */
public struct PlaylistDetails: Hashable {
    
    /// *Optional*. The new name for the playlist.
    public var name: String?
    
    /// *Optional*. If `true` the playlist will be public;
    /// if `false` it will be private. Default: `true`.
    public var isPublic: Bool?

    /**
     *Optional*. If `true`, the playlist will become collaborative
     and other users will be able to modify the playlist in their
     Spotify client. Default: `false`.
    
     - Warning: You can only set collaborative to `true` on non-public
           playlists.
     */
    public var isCollaborative: Bool?

    /// This property has been renamed to `isCollaborative`.
    @available(*, deprecated, renamed: "isCollaborative")
    public var collaborative: Bool? { isCollaborative }
    
    /// *Optional*. A new playlist description as displayed in
    /// Spotify Clients and in the Web API.
    public var description: String?
    
    /**
     Creates an instance that holds new details about a playlist.
     All of the properties are optional The value of each non-`nil`
     property will be used update the details of the playlist.
     
     - Parameters:
       - name: The new name for the playlist.
       - isPublic: If `true` the playlist will be public;
             if `false` it will be private. Default: `true`.
       - collaborative: If `true`, the playlist will become collaborative
             and other users will be able to modify the playlist in their
             Spotify client. Default: `false`. **Note**: You can only set
             collaborative to `true` on non-public playlists.
       - description: A new playlist description as displayed in
             Spotify Clients and in the Web API.
     */
    public init(
        name: String? = nil,
        isPublic: Bool? = nil,
        isCollaborative: Bool? = nil,
        description: String? = nil
    ) {
        self.name = name
        self.isPublic = isPublic
        self.isCollaborative = isCollaborative
        self.description = description
    }
    
    /// This method has been renamed to
    /// `init(name:isPublic:isCollaborative:description:)`.
    @available(*, deprecated, renamed: "init(name:isPublic:isCollaborative:description:)")
    public init(
        name: String? = nil,
        isPublic: Bool? = nil,
        collaborative: Bool? = nil,
        description: String? = nil
    ) {
        self.name = name
        self.isPublic = isPublic
        self.isCollaborative = collaborative
        self.description = description
    }
    
    
}

extension PlaylistDetails: Codable {
    
    /// :nodoc:
    public enum CodingKeys: String, CodingKey {
        case name
        case isPublic = "public"
        case isCollaborative = "collaborative"
        case description
    }
    
}
