import Foundation

#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineDispatch
import OpenCombineFoundation
#endif

import XCTest
import SpotifyWebAPI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Assert that a url exists by making a data task request
/// and asserting that the status code is 200.
public func assertURLExists(
    _ url: URL,
    file: StaticString = #file,
    line: UInt = #line
) -> AnyPublisher<Void, URLError> {
    
    var request = URLRequest(url: url)
    request.httpMethod = "HEAD"
    
    #if canImport(Combine)
    let publisher = URLSession.shared.dataTaskPublisher(for: request)
    #else
    let publisher = URLSession.OCombine(.shared).dataTaskPublisher(for: request)
    #endif
    return publisher
        .XCTAssertNoFailure(file: file, line: line)
        .map { data, response in
            let httpURLResponse = response as! HTTPURLResponse
            XCTAssertEqual(
                httpURLResponse.statusCode, 200,
                "unexpected status code for \(url)",
                file: file, line: line
            )
        }
        .eraseToAnyPublisher()
        

}

public extension StringProtocol {
    
    /// Parses an id from a uri by returning all characters after the
    /// last ":".
    var spotifyId: String? {
        return self.split(separator: ":").last.map { String($0) }
    }

}

/// Assert the Spotify user is "petervschorn".
public func assertUserIsPeter(
    _ user: SpotifyUser,
    file: StaticString = #filePath,
    line: UInt = #line
) {
 
    XCTAssertEqual(
        user.href,
        "https://api.spotify.com/v1/users/petervschorn",
        file: file, line: line
    )
    XCTAssertEqual(
        user.id, "petervschorn",
        file: file, line: line
    )
    XCTAssertEqual(
        user.uri,
        "spotify:user:petervschorn",
        file: file, line: line
    )
    XCTAssertEqual(
        user.type, .user,
        file: file, line: line
    )
    
}

/**
 Assert that a publisher finished normally. If not, call through to
 `XCTFail`.
 
 - Parameters:
   - completion: A completion from a publisher.
   - message: A message to prefix the error with.
   - file: The file in which the error occured.
   - line: The line in which the error occured.
 */
public func XCTAssertFinishedNormally<E: Error>(
    _ completion: Subscribers.Completion<E>,
    _ message: String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    if case .failure(let error) = completion {
        let msg = message.isEmpty ? "" : "\(message): "
        XCTFail("\(msg)\(error)", file: file, line: line)
    }
}


/**
 Assert the the Spotify Images exist.
 
 - Parameter images: An array of Spotify images.
 - Returns: An array of expectations that will be fullfilled when
       each image is loaded from its URL.
 */
#if (canImport(AppKit) || canImport(UIKit)) && canImport(SwiftUI)
public func XCTAssertImagesExist(
    _ images: [SpotifyImage],
    file: StaticString = #file,
    line: UInt = #line
) -> (expectations: [XCTestExpectation], cancellables: Set<AnyCancellable>) {
    var cancellables: Set<AnyCancellable> = []
    var imageExpectations: [XCTestExpectation] = []
    for (i, image) in images.enumerated() {
        XCTAssertNotNil(image.height)
        XCTAssertNotNil(image.width)
        guard let url = URL(string: image.url) else {
            XCTFail("couldn't convert to URL: '\(image.url)'")
            continue
        }
        let existsExpectation = XCTestExpectation(
            description: "image exists \(i)"
        )
        imageExpectations.append(existsExpectation)
        
        assertURLExists(url, file: file, line: line)
            .sink(receiveCompletion: { _ in
                existsExpectation.fulfill()
            })
            .store(in: &cancellables)

        let loadExpectation = XCTestExpectation(
            description: "load image \(i)"
        )
        imageExpectations.append(loadExpectation)
        
        image.load()
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in
                    loadExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    return (expectations: imageExpectations, cancellables: cancellables)
}
#endif



public extension Scope {
    
    /**
     All the scopes that are related to playlists
     
     * `playlistReadCollaborative`
     * `playlistModifyPublic`
     * `playlistReadPrivate`
     * `playlistModifyPrivate`
     * `ugcImageUpload` (required for uploading an image to a playlist)
     */
    static let playlistScopes: Set<Scope> = [
        .playlistReadCollaborative,
        .playlistModifyPublic,
        .playlistReadPrivate,
        .playlistModifyPrivate,
        .ugcImageUpload
    ]

}

public extension URLSession {
    
    /**
     Sets the `cachePolicy` of the `URLRequest` to
     `reloadIgnoringLocalAndRemoteCacheData`.
     
     Useful for tests that need to produce a rate limited error.
     */
    func noCacheNetworkAdaptor(
        request: URLRequest
    ) -> AnyPublisher<(data: Data, response: HTTPURLResponse), Error> {
        
        var request = request
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        return self.dataTaskPublisher(for: request)
            .mapError { $0 as Error }
            .map { data, response -> (data: Data, response: HTTPURLResponse) in
                guard let httpURLResponse = response as? HTTPURLResponse else {
                    fatalError(
                        "could not cast URLResponse to HTTPURLResponse:\n\(response)"
                    )
                }
                return (data: data, response: httpURLResponse)
            }
            .eraseToAnyPublisher()

    }


}

@available(macOS 10.15.4, iOS 13.4, macCatalyst 13.4, tvOS 13.4, watchOS 6.2, *)
public extension String {
    
    func append(to file: URL, terminator: String = "\n") throws {

        var data = self.data(using: .utf8)!
        let terminatorData = terminator.data(using: .utf8)!
        data.append(terminatorData)

        let manager = FileManager.default
        

        if manager.fileExists(atPath: file.path) {
            let handle = try FileHandle(forUpdating: file)
            do {
                try handle.seekToEnd()
                handle.write(data)
                try handle.close()

            } catch {
                try handle.close()
                throw error
            }
            
        }
        else {
            try data.write(to: file, options: [.atomic])
        }
        
    }

}