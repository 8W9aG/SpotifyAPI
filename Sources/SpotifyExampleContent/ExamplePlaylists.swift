import Foundation
import SpotifyWebAPI

#if SWIFT_TOOLS_5_3

public extension PagingObject where Item == PlaylistItemContainer<Track> {
    
    /// Sample data for testing purposes.
    static let thisIsJimiHendrix = Bundle.module.decodeJson(
        forResource: "This is Jimi Hendrix - PagingObject<PlaylistItemContainer<Track>>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let thisIsPinkFloyd = Bundle.module.decodeJson(
        forResource: "This is Pink Floyd - PagingObject<PlaylistItemContainer<Track>>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let thisIsMacDeMarco = Bundle.module.decodeJson(
        forResource: "This is Mac DeMarco - PagingObject<PlaylistItemContainer<Track>>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let thisIsSpoon = Bundle.module.decodeJson(
        forResource: "This Is Spoon - PagingObject<PlaylistItemContainer<Track>>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let bluesClassics = Bundle.module.decodeJson(
        forResource: "Blues Classics - PagingObject<PlaylistItemContainer<Track>>",
        type: Self.self
    )!

}


public extension PagingObject where Item == PlaylistItemContainer<PlaylistItem> {
    
    
    /// Sample data for testing purposes.
    static let thisIsStevieRayVaughan = Bundle.module.decodeJson(
        forResource: "This is Stevie Ray Vaughan - PagingObject<PlaylistItemContainer<PlaylistItem>>",
        type: Self.self
    )!

}

public extension Playlist where Items == PlaylistItems {
    
    /// Sample data for testing purposes.
    ///
    /// This playlist episodes and local tracks. Local tracks
    /// often have most of their properties set to `nil`, which can be very
    /// useful for testing purposes.
    static let episodesAndLocalTracks = Bundle.module.decodeJson(
        forResource: "Local Songs - Playlist<PagingObject<PlaylistItemContainer<PlaylistItem>>>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let crumb = Bundle.module.decodeJson(
        forResource: "Crumb - Playlist<PagingObject<PlaylistItemContainer<PlaylistItem>>>",
        type: Self.self
    )!
    
}

public extension Playlist where Items == PlaylistItemsReference {
    
    /// Sample data for testing purposes.
    static let lucyInTheSkyWithDiamonds = Bundle.module.decodeJson(
        forResource: "Lucy in the sky with diamonds - Playlist<PlaylistItemsReference>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let thisIsMFDoom = Bundle.module.decodeJson(
        forResource: "This Is MF DOOM - Playlist<PlaylistItemsReference>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let rockClassics = Bundle.module.decodeJson(
        forResource: "Rock Classics - Playlist<PlaylistItemsReference>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let thisIsSonicYouth = Bundle.module.decodeJson(
        forResource: "This Is Sonic Youth - Playlist<PlaylistItemsReference>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let thisIsRadiohead = Bundle.module.decodeJson(
        forResource: "This Is Radiohead - Playlist<PlaylistItemsReference>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let thisIsSkinshape = Bundle.module.decodeJson(
        forResource: "This is Skinshape - Playlist<PlaylistItemsReference>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let modernPsychedelia = Bundle.module.decodeJson(
        forResource: "Modern Psychedelia - Playlist<PlaylistItemsReference>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let thisIsMildHighClub = Bundle.module.decodeJson(
        forResource: "This Is Mild High Club - Playlist<PlaylistItemsReference>",
        type: Self.self
    )!
    
    /// Sample data for testing purposes.
    static let menITrust = Bundle.module.decodeJson(
        forResource: "Men I Trust - Playlist<PlaylistItemsReference>",
        type: Self.self
    )!

}

#endif
