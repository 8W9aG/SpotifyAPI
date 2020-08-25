import Foundation
import Combine

public extension SpotifyAPI {
    
    /**
     Get a Track.
     
     See also `tracks(_:market:)` (gets multiple track).
     
     No scopes are required for this endpoint.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameters:
       - uri: The URI for a track.
       - market: *Optional*. An ISO 3166-1 alpha-2 country code or
             the string "from_token". Provide this parameter if you want
             to apply [Track Relinking][2].
     - Returns: The full version of a track.

     [1]: https://developer.spotify.com/documentation/web-api/reference/tracks/get-track/
     [2]: https://developer.spotify.com/documentation/general/guides/track-relinking-guide/
     */
    func track(
        _ uri: SpotifyURIConvertible,
        market: String? = nil
    ) -> AnyPublisher<Track, Error> {
        
        do {
            
            let trackId = try SpotifyIdentifier(uri: uri).id
            
            return self.getRequest(
                path: "/tracks/\(trackId)",
                queryItems: ["market": market],
                requiredScopes: []
            )
            .spotifyDecode(Track.self)
            
        } catch {
            return error.anyFailingPublisher(Track.self)
        }
        
    }
    
    /**
     Get multiple Tracks.
     
     See also `track(_:market:)` (gets a single track).
     
     No scopes are required for this endpoint.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameters:
       - uris: An array of track URIs. Maximum: 50.
       - market: *Optional*. An ISO 3166-1 alpha-2 country code or
             the string "from_token". Provide this parameter if you want
             to apply [Track Relinking][2].
     - Returns: The full versions of up to 50 tracks. Tracks are returned in
           the order requested. If a track is not found, `nil` is
           returned in the appropriate position. Duplicate tracks URIs
           in the request will result in duplicate tracks in the response.
           
     [1]: https://developer.spotify.com/documentation/web-api/reference/tracks/get-several-tracks/
     [2]: https://developer.spotify.com/documentation/general/guides/track-relinking-guide/
     */
    func tracks(
        _ uris: [SpotifyURIConvertible],
        market: String? = nil
    ) -> AnyPublisher<[Track?], Error> {
        
        do {
            
            let trackIds = try SpotifyIdentifier
                    .commaSeparatedIdsString(uris)
            
            return self.getRequest(
                path: "/tracks",
                queryItems: [
                    "ids": trackIds,
                    "market": market
                ],
                requiredScopes: []
            )
            .spotifyDecode([String: [Track?]].self)
            .tryMap { dict -> [Track?] in
                if let tracks = dict["tracks"] {
                    return tracks
                }
                throw SpotifyLocalError.topLevelKeyNotFound(
                    key: "tracks", dict: dict
                )
            }
            .eraseToAnyPublisher()
            
        } catch {
            return error.anyFailingPublisher([Track?].self)
        }
        
    }
    
}