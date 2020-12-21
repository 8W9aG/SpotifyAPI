import Foundation
import XCTest
#if canImport(Combine)
import Combine
#else
import OpenCombine


#endif
@testable import SpotifyWebAPI
import SpotifyAPITestUtilities
import SpotifyExampleContent

protocol SpotifyAPIUserProfileTests: SpotifyAPITests { }

extension SpotifyAPIUserProfileTests {
    
    func userProfile() {
        
        func receiveUser(_ user: SpotifyUser) {
            XCTAssertEqual(user.displayName, "April")
            XCTAssertEqual(
                user.href,
                "https://api.spotify.com/v1/users/p8gjjfbirm8ucyt82ycfi9zuu"
            )
            XCTAssertEqual(user.id, "p8gjjfbirm8ucyt82ycfi9zuu")
            XCTAssertEqual(user.type, .user)
            XCTAssertEqual(user.uri, "spotify:user:p8gjjfbirm8ucyt82ycfi9zuu")
            
            if let externalURLs = user.externalURLs {
                XCTAssertEqual(
                    externalURLs["spotify"],
                    "https://open.spotify.com/user/p8gjjfbirm8ucyt82ycfi9zuu",
                    "\(externalURLs)"
                )
            }
            else {
                XCTFail("externalURLs should not be nil")
            }

            XCTAssertNotNil(user.followers)
            
            guard let images = user.images else {
                XCTFail("April should have images for her acount")
                return
            }

            var imageExpectations: [XCTestExpectation] = []
            for (i, image) in images.enumerated() {
                guard let url = URL(string: image.url) else {
                    XCTFail("couldn't convert string to URL: '\(image.url)'")
                    continue
                }
                let expectation = XCTestExpectation(
                    description: "assert image url exists \(i)"
                )
                imageExpectations.append(expectation)
                
                assertURLExists(url)
                    .XCTAssertNoFailure()
                    .sink(
                        receiveCompletion: { _ in
                            expectation.fulfill()
                        }
                    )
                    .store(in: &Self.cancellables)
            }
            self.wait(
                for: imageExpectations,
                timeout: TimeInterval(60 * imageExpectations.count)
            )
            
        }
        
        let expectation = XCTestExpectation(
            description: "testUserProfile"
        )
        
        Self.spotify.userProfile(URIs.Users.april)
            .XCTAssertNoFailure()
            .receiveOnMain()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: receiveUser(_:)
            )
            .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 120)

    }

}


extension SpotifyAPIUserProfileTests where
    AuthorizationManager: SpotifyScopeAuthorizationManager
{
    
    func currentUserProfile() {
        
        func receiveCurrentUserProfile(_ user: SpotifyUser) {
            XCTAssertEqual(user.type, .user)
            XCTAssert(user.uri.starts(with: "spotify:user:"))
            do {
                let identifier = try SpotifyIdentifier(
                    uri: user.uri, ensureCategoryMatches: [.user]
                )
                XCTAssertEqual(user.id, identifier.id)
                XCTAssertEqual(user.uri, identifier.uri)
                XCTAssertEqual(identifier.idCategory, .user)
            } catch {
                XCTFail("\(error)")
            }
           
        }
        
        let expectation = XCTestExpectation(
            description: "testCurrentUserProfile"
        )
        
        Self.spotify.currentUserProfile()
            .XCTAssertNoFailure()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: receiveCurrentUserProfile(_:)
            )
            .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 120)
        
    }

}

final class SpotifyAPIClientCredentialsFlowUserProfileTests:
    SpotifyAPIClientCredentialsFlowTests, SpotifyAPIUserProfileTests
{
    
    static let allTests = [
        ("testUserProfile", testUserProfile)
    ]
    
    func testUserProfile() { userProfile() }
    
}

final class SpotifyAPIAuthorizationCodeFlowUserProfileTests:
    SpotifyAPIAuthorizationCodeFlowTests, SpotifyAPIUserProfileTests
{
    
    static let allTests = [
        ("testUserProfile", testUserProfile),
        ("testCurrentUserProfile", testCurrentUserProfile)
    ]
    
    func testUserProfile() { userProfile() }
    func testCurrentUserProfile() { currentUserProfile() }
    
}

final class SpotifyAPIAuthorizationCodeFlowPKCEUserProfileTests:
    SpotifyAPIAuthorizationCodeFlowPKCETests, SpotifyAPIUserProfileTests
{
    static let allTests = [
        ("testUserProfile", testUserProfile),
        ("testCurrentUserProfile", testCurrentUserProfile)
    ]
    
    func testUserProfile() { userProfile() }
    func testCurrentUserProfile() { currentUserProfile() }
    
}
