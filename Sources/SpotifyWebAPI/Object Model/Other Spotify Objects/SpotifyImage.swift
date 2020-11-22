import Foundation
import SwiftUI
import Combine

#if canImport(AppKit)
import AppKit
/// `NSImage` on macOS; else, `UIImage`.
typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
/// `NSImage` on macOS; else, `UIImage`.
typealias PlatformImage = UIImage
#endif


/**
 A Spotify [image][1] object.

 Includes the URL to the image and its height and width.
 
  - Warning: If this image belongs to a playlist, then the URL is
        temporary and will expire in less than a day. Use
        `SpotifyAPI.playlistImage(_:)` to retrieve the image
        for a playlist.
 
 [1]: https://developer.spotify.com/documentation/web-api/reference/object-model/#image-object
 */
public struct SpotifyImage: Codable, Hashable {
    
    /// The image height in pixels.
    /// May be `nil`, especially if uploaded by a user.
    public let height: Int?
    
    /// The image width in pixels.
    /// May be `nil`, especially if uploaded by a user.
    public let width: Int?
    
    /**
     The source URL of the image.
     
     Consider using `self.load()` to load the image from this URL.
     
     - Warning: If this image belongs to a playlist, then it is
           temporary and will expire in less than a day. Use
           `SpotifyAPI.playlistImage(_:)` to retrieve the image
           for a playlist.
     */
    public let url: String

    /**
     Creates a Spotify [image][1] object.
     
     - Parameters:
       - height: The image height in pixels.
       - width: The image width in pixels.
       - url: The source URL of the image.
     
     [1]: https://developer.spotify.com/documentation/web-api/reference/object-model/#image-object
     */
    public init(
        height: Int? = nil,
        width: Int? = nil,
        url: String
    ) {
        self.height = height
        self.width = width
        self.url = url
    }

}

public extension SpotifyImage {
    
    #if canImport(AppKit) || canImport(UIKit)
    /// Loads the image from `self.url`.
    ///
    /// Fails if `self.url` cannot be converted to `URL`, if the data
    /// cannot be converted to `Image`, or if some other network error occurs.
    func load() -> AnyPublisher<Image, Error> {

        guard let imageURL = URL(string: url) else {
            return SpotifyLocalError.other(
                "couldn't convert string to URL: '\(url)'"
            )
            .anyFailingPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: imageURL)
            .tryMap { data, response -> Image in
                
                if let image = PlatformImage(data: data).map({
                    image -> Image in
                    
                    #if canImport(AppKit)
                    return Image(nsImage: image)
                    #elseif canImport(UIKit)
                    return Image(uiImage: image)
                    #endif
                }) {
                    return image
                }
                throw SpotifyLocalError.other(
                    "couldn't convert data to image"
                )
                
            }
            .eraseToAnyPublisher()
        
    }
    #endif
    
}

public extension Sequence where Element == SpotifyImage {
    
    /**
     Returns the largest image in this sequence
     of `SpotifyImage`, or `nil` if the sequence is empty.
    
     When determining the largest image, Images with
     `nil` for `height` and/or `width` are considered
     to have a `height` and/or `width` of 0.
     
     The largest image is calculated based on `height` * `width`.
     */
    var largest: SpotifyImage? {
        
        // areInIncreasingOrder
        // A predicate that returns true if its first argument should
        // be ordered before its second argument; otherwise, false.
        return self.max(by: { (lhs: SpotifyImage, rhs: SpotifyImage) -> Bool in
            let lhsDimensions = (lhs.width ?? 0) * (lhs.height ?? 0)
            let rhsDimensions = (rhs.width ?? 0) * (rhs.height ?? 0)
            return lhsDimensions < rhsDimensions
        })
        
    }
    
}
