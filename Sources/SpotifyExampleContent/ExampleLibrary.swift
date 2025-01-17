import Foundation
import SpotifyWebAPI


public extension PagingObject where Item == SavedItem<Album> {
    
    /// Sample data for testing purposes.
    static let sampleCurrentUserSavedAlbums = Bundle.module.decodeJSON(
        forResource: "Current User Saved Albums - PagingObject<SavedItem<Album>>",
        type: Self.self
    )!

}
