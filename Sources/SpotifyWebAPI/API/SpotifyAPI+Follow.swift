import Foundation
import Combine

private extension SpotifyAPI {
    
    /// Check if the current user is following the specified
    /// artists/users.
    func currentUserFollowingContains(
        uris: [SpotifyURIConvertible],
        type: IDCategory
    ) -> AnyPublisher<[Bool], Error> {
        
        do {
            
            if uris.isEmpty {
                return Result<[Bool], Error>.Publisher(.success([]))
                    .eraseToAnyPublisher()
            }

            let idsString = try SpotifyIdentifier
                    .commaSeparatedIdsString(uris, ensureAllTypesAre: type)
            
            return self.getRequest(
                path: "/me/following/contains",
                queryItems: [
                    "type": type.rawValue,
                    "ids": idsString
                ],
                requiredScopes: [.userFollowRead]
            )
            .decodeSpotifyObject([Bool].self)

        } catch {
            return error.anyFailingPublisher([Bool].self)
        }

    }

    /// Follow and unfollow artists and users.
    func modifyCurrentUserFollowing(
        uris: [SpotifyURIConvertible],
        type: IDCategory,
        httpMethod: String
    ) -> AnyPublisher<Void, Error> {
        
        do {
            
            if uris.isEmpty {
                return Result<Void, Error>.Publisher(.success(()))
                    .eraseToAnyPublisher()
            }
            
            let idsString = try SpotifyIdentifier
                    .commaSeparatedIdsString(uris, ensureAllTypesAre: type)

            return self.apiRequest(
                path: "/me/following",
                queryItems: ["type": type.rawValue],
                httpMethod: httpMethod,
                makeHeaders: Headers.bearerAuthorizationAndacceptApplicationJSON(_:),
                body: ["ids": idsString],
                requiredScopes: [.userFollowModify]
            )
            .decodeSpotifyErrors()
            .map { _, _ in }
            .eraseToAnyPublisher()
            
            
        } catch {
            return error.anyFailingPublisher(Void.self)
        }

    }
    
}

// MARK: Follow

public extension SpotifyAPI {
    
    /**
     Check if the current user follows the specified artists.
     
     See also `currentUserFollowsUsers(_:)` and
     `usersFollowPlaylist(_:userURIs:)`.
     
     This endpoint requires the `userFollowRead` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of artist URIs. Maximum: 50.
           Passing in duplicates will result in a
           502 "Failed to check following status" error.
     - Returns: An array of `true` or `false` values,
           in the order requested, indicating whether the user
           is following each artist.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/follow/check-current-user-follows/
     */
    func currentUserFollowsArtists(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<[Bool], Error> {
        
        return self.currentUserFollowingContains(
            uris: uris, type: .artist
        )

    }
    
    /**
     Check if the current user follows the specified users.
     
     See also `currentUserFollowsArtists(_:)` and
     `usersFollowPlaylist(_:userURIs:)`.
     
     This endpoint requires the `userFollowRead` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of user URIs. Maximum: 50.
           Passing in duplicates will result in a
           502 "Failed to check following status" error.
     - Returns: An array of `true` or `false` values,
           in the order requested, indicating whether the user
           is following each user.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/follow/check-current-user-follows/
     */
    func currentUserFollowsUsers(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<[Bool], Error> {
        
        return self.currentUserFollowingContains(
            uris: uris, type: .user
        )

    }

    /**
     Check to see if one or more Spotify users are following
     a specified playlist.
     
     See also `currentUserFollowsArtists(_:)` and
     `currentUserFollowsUsers(_:)`
     
     Following a playlist can be done publicly or privately.
     Checking if a user publicly follows a playlist doesn’t require
     any scopes; if the user is publicly following the playlist, this
     endpoint returns `true`. Checking if the user is privately following
     a playlist is only possible for the current user when that user has
     granted access to the `playlistReadPrivate` scope.
     
     If the user has created the playlist themself (or you created it for them)
     and it shows up in their Spotify client, then that also means that they
     are following it. See also [Following and Unfollowing a Playlist][1].
     
     Read more at the [Spotify web API reference][2].
     
     - Parameters:
       - uri: The URI for a playlist
       - userURIs: An array of up to **5** user URIs.
     - Returns: An array of `true` or `false` values,
           in the order requested, indicating whether each
           user is following the playlist.
     
     [1]: https://developer.spotify.com/documentation/general/guides/working-with-playlists/#following-and-unfollowing-a-playlist
     [2]: https://developer.spotify.com/documentation/web-api/reference/follow/check-user-following-playlist/
     */
    func usersFollowPlaylist(
        _ uri: SpotifyURIConvertible,
        userURIs: [SpotifyURIConvertible]
    ) -> AnyPublisher<[Bool], Error> {
        
        do {
            
            if userURIs.isEmpty {
                return Result<[Bool], Error>.Publisher(.success([]))
                    .eraseToAnyPublisher()
            }
            
            let playlistId = try SpotifyIdentifier(uri: uri).id
            
            let userIdsString = try SpotifyIdentifier
                    .commaSeparatedIdsString(userURIs)
            
            return self.getRequest(
                path: "/playlists/\(playlistId)/followers/contains",
                queryItems: [
                    "ids": userIdsString
                ],
                requiredScopes: []
            )
            .decodeSpotifyObject([Bool].self)
            
        } catch {
            return error.anyFailingPublisher([Bool].self)
        }

    }
    
    /**
     Add the current user as a follower of one or more artists.
     
     See also `followUsersForCurrentUser(_:)` and
     `followPlaylistForCurrentUser(_:publicly:)`.
     
     This endpoint requires the `userFollowModify` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of artist URIs. Maximum: 50.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/follow/follow-artists-users/
     */
    func followArtistsForCurrentUser(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<Void, Error> {
        
        return self.modifyCurrentUserFollowing(
            uris: uris, type: .artist, httpMethod: "PUT"
        )

    }
    
    /**
     Add the current user as a follower of one or more users.
     
     See also `followArtistsForCurrentUser(_:)` and
     `followPlaylistForCurrentUser(_:publicly:)`.
     
     This endpoint requires the `userFollowModify` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of user URIs. Maximum: 50.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/follow/follow-artists-users/
     */
    func followUsersForCurrentUser(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<Void, Error> {
        
        return self.modifyCurrentUserFollowing(
            uris: uris, type: .user, httpMethod: "PUT"
        )

    }
    
    /**
     Unfollow one or more artists for the current user.

     See also `unfollowUsersForCurrentUser(_:)` and
     `unfollowPlaylistForCurrentUser(_:)`.
     
     This endpoint requires the `userFollowModify` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of artist URIs. maximum: 50.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/follow/unfollow-artists-users/
     */
    func unfollowArtistsForCurrentUser(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<Void, Error> {
        
        return self.modifyCurrentUserFollowing(
            uris: uris, type: .artist, httpMethod: "DELETE"
        )
        
    }
    
    /**
     Unfollow one or more users for the current user.

     See also `unfollowArtistsForCurrentUser(_:)` and
     `unfollowPlaylistForCurrentUser(_:)`.
     
     This endpoint requires the `userFollowModify` scope.
     
     Read more at the [Spotify web API reference][1].
     
     - Parameter uris: An array of user URIs. maximum: 50.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/follow/unfollow-artists-users/
     */
    func unfollowUsersForCurrentUser(
        _ uris: [SpotifyURIConvertible]
    ) -> AnyPublisher<Void, Error> {
        
        return self.modifyCurrentUserFollowing(
            uris: uris, type: .user, httpMethod: "DELETE"
        )
        
    }
    
    /**
     Follow a playlist for the current user.
     
     See also `followArtistsForCurrentUser(_:)` and
     `followUsersForCurrentUser(_:)`.
     
     Following a playlist publicly requires authorization of the
     `playlistModifyPublic` scope; following it privately requires
     the `playlistModifyPrivate` scope.
     
     Note that the scopes you provide relate only to whether the
     current user is following the playlist publicly or privately
     (i.e. showing others what they are following), not whether the
     playlist itself is public or private.
     
     See also the guide for [working with playlists][1].
     
     Read more at the [Spotify web API reference][2].
     
     - Parameters:
       - uri: The URI for a playlist.
       - publicly: *Optional*. Defaults to `true`. If `true`, the playlist
             will be included in the user’s public playlists, if `false`, it
             will remain private. To be able to follow playlists privately,
             the user must have granted the `playlistModifyPrivate` scope.
     
     [1]: https://developer.spotify.com/documentation/general/guides/working-with-playlists/
     [2]: https://developer.spotify.com/documentation/web-api/reference/follow/follow-playlist/
     */
    func followPlaylistForCurrentUser(
        _ uri: SpotifyURIConvertible,
        publicly: Bool = true
    ) -> AnyPublisher<Void, Error> {
        
        do {
            
            let playlistId = try SpotifyIdentifier(uri: uri).id
            
            return self.apiRequest(
                path: "/playlists/\(playlistId)/followers",
                queryItems: [:],
                httpMethod: "PUT",
                makeHeaders: Headers.bearerAuthorizationAndacceptApplicationJSON(_:),
                body: ["public": publicly],
                requiredScopes: []
            )
            .decodeSpotifyErrors()
            .map { _, _ in }
            .eraseToAnyPublisher()

        } catch {
            return error.anyFailingPublisher(Void.self)
        }

    }
    
    /**
     Unfollow a playlist for the current user.

     See also `unfollowArtistsForCurrentUser(_:)` and
     `unfollowUsersForCurrentUser(_:)`.
     
     Spotify has no concept of deleting playlists. When a user
     deletes a playlist in their Spotify client, they are actually
     just unfollowing it. The playlist can always be retrieved again
     given a valid URI.
     
     Unfollowing a publicly followed playlist for a user requires
     authorization of the `playlistModifyPublic` scope; unfollowing
     a privately followed playlist requires the `playlistModifyPrivate`
     scope.
     
     Note that the scopes you provide relate only to whether the
     current user is following the playlist publicly or privately
     (i.e. showing others what they are following), not whether the
     playlist itself is public or private.
     
     See also the guide for [working with playlists][1].
     
     Read more at the [Spotify web API reference][2].
     
     - Parameters:
       - uri: The URI for a playlist.
     
     [1]: https://developer.spotify.com/documentation/general/guides/working-with-playlists/
     [2]: https://developer.spotify.com/documentation/web-api/reference/follow/follow-playlist/
     */
    func unfollowPlaylistForCurrentUser(
        _ uri: SpotifyURIConvertible
    ) -> AnyPublisher<Void, Error> {
        
        do {
            
            let playlistId = try SpotifyIdentifier(uri: uri).id
            
            return self.apiRequest(
                path: "/playlists/\(playlistId)/followers",
                queryItems: [:],
                httpMethod: "DELETE",
                makeHeaders: Headers.bearerAuthorizationAndacceptApplicationJSON(_:),
                bodyData: nil as Data?,
                requiredScopes: []
            )
            .decodeSpotifyErrors()
            .map { _, _ in }
            .eraseToAnyPublisher()

        } catch {
            return error.anyFailingPublisher(Void.self)
        }

    }
    
    
}