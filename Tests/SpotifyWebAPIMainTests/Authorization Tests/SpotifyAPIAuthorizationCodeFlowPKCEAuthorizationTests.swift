import Foundation
import XCTest
#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineDispatch
import OpenCombineFoundation


#endif
import SpotifyAPITestUtilities
@testable import SpotifyWebAPI

final class SpotifyAPIAuthorizationCodeFlowPKCEAuthorizationTests:
    SpotifyAPIAuthorizationCodeFlowPKCETests
{
    
    static var allTests = [
        ("testDeauthorizeReauthorize", testDeauthorizeReauthorize),
        ("testCodingSpotifyAPI", testCodingSpotifyAPI),
        ("testReassigningAuthorizationManager", testReassigningAuthorizationManager),
        ("testConvenienceInitializer", testConvenienceInitializer),
        ("testInvalidState1", testInvalidState1),
        ("testInvalidState2", testInvalidState2),
        ("testInvalidState3", testInvalidState3),
        ("testInvalidCodeVerifier", testInvalidCodeVerifier)
    ]
    
    func testDeauthorizeReauthorize() {
    
        encodeDecode(Self.spotify.authorizationManager, areEqual: ==)
        
        var didChangeCount = 0
        var cancellables: Set<AnyCancellable> = []
        Self.spotify.authorizationManagerDidChange.sink(receiveValue: {
            didChangeCount += 1
        })
        .store(in: &cancellables)
        
        var didDeauthorizeCount = 0
        Self.spotify.authorizationManagerDidDeauthorize
            .sink(receiveValue: {
                didDeauthorizeCount += 1
            })
            .store(in: &cancellables)
    
        let currentScopes = Self.spotify.authorizationManager.scopes ?? []
    
        XCTAssertTrue(
            Self.spotify.authorizationManager.isAuthorized(for: currentScopes),
            "\(currentScopes)"
        )
        
        Self.spotify.authorizationManager.deauthorize()
        
        XCTAssertNil(Self.spotify.authorizationManager.scopes)
        XCTAssertFalse(Self.spotify.authorizationManager.isAuthorized())
        
        Self.spotify.authorizeAndWaitForTokens(
            scopes: currentScopes
        )
    
        XCTAssertTrue(
            Self.spotify.authorizationManager.isAuthorized(for: currentScopes),
            "\(Self.spotify.authorizationManager.scopes ?? [])"
        )
        XCTAssertEqual(Self.spotify.authorizationManager.scopes, currentScopes)
        XCTAssertFalse(
            Self.spotify.authorizationManager.accessTokenIsExpired(tolerance: 0)
        )
        
        XCTAssertEqual(
            didChangeCount, 1,
            "authorizationManagerDidChange should only emit once"
        )
        XCTAssertEqual(
            didDeauthorizeCount, 1,
            "authorizationManagerDidDeauthorize should only emit once"
        )
        
        encodeDecode(Self.spotify.authorizationManager, areEqual: ==)
    
    }
    
    func testCodingSpotifyAPI() throws {
        
        let spotifyAPIData = try JSONEncoder().encode(Self.spotify)
        
        let decodedSpotifyAPI = try JSONDecoder().decode(
            SpotifyAPI<AuthorizationCodeFlowPKCEManager>.self,
            from: spotifyAPIData
        )
        
        Self.spotify = decodedSpotifyAPI
        
        self.testDeauthorizeReauthorize()
        
    }
    
    func testReassigningAuthorizationManager() {
        
        var didChangeCount = 0
        var cancellables: Set<AnyCancellable> = []
        Self.spotify.authorizationManagerDidChange.sink(receiveValue: {
            didChangeCount += 1
        })
        .store(in: &cancellables)
        
        var didDeauthorizeCount = 0
        Self.spotify.authorizationManagerDidDeauthorize
            .sink(receiveValue: {
                didDeauthorizeCount += 1
            })
            .store(in: &cancellables)
        
        let currentAuthManager = Self.spotify.authorizationManager
        
        Self.spotify.authorizationManager = .init(
            clientId: "client id",
            clientSecret: "client secret"
        )

        Self.spotify.authorizationManager = currentAuthManager
        
        XCTAssertEqual(didChangeCount, 2)
        XCTAssertEqual(didDeauthorizeCount, 0)
        
    }
    
    func testConvenienceInitializer() throws {
        
        let authManagerData = try JSONEncoder().encode(
            Self.spotify.authorizationManager
        )
        
        let decodedAuthManager = try JSONDecoder().decode(
            AuthorizationCodeFlowPKCEManager.self,
            from: authManagerData
        )
        
        guard
            let accessToken = decodedAuthManager.accessToken,
            let expirationDate = decodedAuthManager.expirationDate,
            let refreshToken = decodedAuthManager.refreshToken,
            let scopes = decodedAuthManager.scopes
        else {
            XCTFail("none of the properties should be nil: \(decodedAuthManager)")
            return
        }
        
        let newAuthorizationManager = AuthorizationCodeFlowPKCEManager(
            clientId: decodedAuthManager.clientId,
            clientSecret: decodedAuthManager.clientSecret,
            accessToken: accessToken,
            expirationDate: expirationDate,
            refreshToken: refreshToken,
            scopes: scopes
        )
        
        XCTAssertEqual(Self.spotify.authorizationManager, newAuthorizationManager)

    }
    
    /// No state provided when making the authorization URL; state provided
    /// when requesting the access and refresh tokens. Correct code challenge
    /// and code verifier.
    func testInvalidState1() {
        
        var didChangeCount = 0
        var cancellables: Set<AnyCancellable> = []
        Self.spotify.authorizationManagerDidChange.sink(receiveValue: {
            didChangeCount += 1
        })
        .store(in: &cancellables)
        
        let requestedScopes = Set(Scope.allCases.shuffled().prefix(5))
        let codeVerifier = String.randomURLSafe(length: 128)
        let codeChallenge = codeVerifier.makeCodeChallenge()
        
        let authorizationURL = Self.spotify.authorizationManager.makeAuthorizationURL(
            redirectURI: localHostURL,
            codeChallenge: codeChallenge,
            state: nil,
            scopes: requestedScopes
        )!
        
        let queryDict = authorizationURL.queryItemsDict
        guard let scopesString = queryDict["scope"] else {
            XCTFail("Couldn't find 'scope' in query string: '\(authorizationURL)'")
            return
        }
        let scopesFromQuery = Scope.makeSet(scopesString)
        XCTAssertEqual(requestedScopes, scopesFromQuery)
        
        if let redirectURI = queryDict["redirect_uri"],
               let url = URL(string: redirectURI) {
            XCTAssertEqual(localHostURL, url)
        }
        else {
            XCTFail("couldn't find redirect_uri in query string")
        }
        
        XCTAssertNil(queryDict["state"])
        XCTAssertEqual(queryDict["code_challenge"], codeChallenge)
        
        guard let redirectURL = openAuthorizationURLAndWaitForRedirect(
            authorizationURL
        ) else {
            XCTFail("redirect URL should not be nil")
            return
        }
        
        let expectation = XCTestExpectation(
            description: "testInvalidState: no state when making authorization URL"
        )
        
        let state = String.randomURLSafe(length: 100)
        Self.spotify.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: redirectURL,
            codeVerifier: codeVerifier,
            state: state
        )
        .sink(receiveCompletion: { completion in
        
            defer { expectation.fulfill() }

            guard case .failure(let error) = completion else {
                XCTFail(
                    "publisher should fail with SpotifyLocalError.invalidState"
                )
                return
            }
            guard let localError = error as? SpotifyLocalError else {
                XCTFail("error should be SpotifyLocalError")
                return
            }
            print(localError)
            guard case .invalidState(let supplied, let received) = localError else {
                XCTFail("case should be invalidState: \(localError)")
                return
            }
            XCTAssertEqual(supplied, state)
            XCTAssertNil(received)
        
        })
        .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 300)
        XCTAssertEqual(didChangeCount, 0)
    
    }
    
    /// State provided when making the authorization URL, but no state provided
    /// when requesting the access and refresh tokens. Correct code challenge
    /// and code verifier.
    func testInvalidState2() {
        
        var didChangeCount = 0
        var cancellables: Set<AnyCancellable> = []
        Self.spotify.authorizationManagerDidChange.sink(receiveValue: {
            didChangeCount += 1
        })
        .store(in: &cancellables)
        
        let requestedScopes = Set(Scope.allCases.shuffled().prefix(5))
        let codeVerifier = String.randomURLSafe(length: 128)
        let codeChallenge = codeVerifier.makeCodeChallenge()
        let authorizationState = String.randomURLSafe(length: 128)
        
        let authorizationURL = Self.spotify.authorizationManager.makeAuthorizationURL(
            redirectURI: localHostURL,
            codeChallenge: codeChallenge,
            state: authorizationState,
            scopes: requestedScopes
        )!
        
        let queryDict = authorizationURL.queryItemsDict
        guard let scopesString = queryDict["scope"] else {
            XCTFail("Couldn't find 'scope' in query string: '\(authorizationURL)'")
            return
        }
        let scopesFromQuery = Scope.makeSet(scopesString)
        XCTAssertEqual(requestedScopes, scopesFromQuery)
        
        if let redirectURI = queryDict["redirect_uri"],
               let url = URL(string: redirectURI) {
            XCTAssertEqual(localHostURL, url)
        }
        else {
            XCTFail("couldn't find redirect_uri in query string")
        }
        
        XCTAssertEqual(queryDict["state"], authorizationState)
        XCTAssertEqual(queryDict["code_challenge"], codeChallenge)
        
        guard let redirectURL = openAuthorizationURLAndWaitForRedirect(
            authorizationURL
        ) else {
            XCTFail("redirect URL should not be nil")
            return
        }
        
        let expectation = XCTestExpectation(
            description: "testInvalidState: no state when requesting access " +
                         "and refresh tokens"
        )
        
        Self.spotify.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: redirectURL,
            codeVerifier: codeVerifier,
            state: nil
        )
        .sink(receiveCompletion: { completion in
        
            defer { expectation.fulfill() }

            guard case .failure(let error) = completion else {
                XCTFail(
                    "publisher should fail with SpotifyLocalError.invalidState"
                )
                return
            }
            guard let localError = error as? SpotifyLocalError else {
                XCTFail("error should be SpotifyLocalError")
                return
            }
            print(localError)
            guard case .invalidState(let supplied, let received) = localError else {
                XCTFail("case should be invalidState: \(localError)")
                return
            }
            XCTAssertNil(supplied)
            XCTAssertEqual(received, authorizationState)
        
        })
        .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 300)
        XCTAssertEqual(didChangeCount, 0)

    }
    
    /// State provided when making the authorization URL did not match the state
    /// provided when requesting the access and refresh tokens. Correct code
    /// challenge and code verifier.
    func testInvalidState3() {
        
        var didChangeCount = 0
        var cancellables: Set<AnyCancellable> = []
        Self.spotify.authorizationManagerDidChange.sink(receiveValue: {
            didChangeCount += 1
        })
        .store(in: &cancellables)
        
        let requestedScopes = Set(Scope.allCases.shuffled().prefix(5))
        let codeVerifier = String.randomURLSafe(length: 128)
        let codeChallenge = codeVerifier.makeCodeChallenge()
        let authorizationState = String.randomURLSafe(length: 100)
        
        let authorizationURL = Self.spotify.authorizationManager.makeAuthorizationURL(
            redirectURI: localHostURL,
            codeChallenge: codeChallenge,
            state: authorizationState,
            scopes: requestedScopes
        )!
        
        let queryDict = authorizationURL.queryItemsDict
        guard let scopesString = queryDict["scope"] else {
            XCTFail("Couldn't find 'scope' in query string: '\(authorizationURL)'")
            return
        }
        let scopesFromQuery = Scope.makeSet(scopesString)
        XCTAssertEqual(requestedScopes, scopesFromQuery)
        
        if let redirectURI = queryDict["redirect_uri"],
               let url = URL(string: redirectURI) {
            XCTAssertEqual(localHostURL, url)
        }
        else {
            XCTFail("couldn't find redirect_uri in query string")
        }
        
        XCTAssertEqual(queryDict["state"], authorizationState)
        XCTAssertEqual(queryDict["code_challenge"], codeChallenge)
        
        guard let redirectURL = openAuthorizationURLAndWaitForRedirect(
            authorizationURL
        ) else {
            XCTFail("redirect URL should not be nil")
            return
        }
        
        let expectation = XCTestExpectation(
            description: "testInvalidState: different state"
        )
        
        let tokensState = String.randomURLSafe(length: 100)
        precondition(tokensState != authorizationState)
        
        Self.spotify.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: redirectURL,
            codeVerifier: codeVerifier,
            state: tokensState
        )
        .sink(receiveCompletion: { completion in
            
            defer { expectation.fulfill() }

            guard case .failure(let error) = completion else {
                XCTFail(
                    "publisher should fail with SpotifyLocalError.invalidState"
                )
                return
            }
            guard let localError = error as? SpotifyLocalError else {
                XCTFail("error should be SpotifyLocalError")
                return
            }
            print(localError)
            guard case .invalidState(let supplied, let received) = localError else {
                XCTFail("case should be invalidState: \(localError)")
                return
            }
            XCTAssertEqual(supplied, tokensState)
            XCTAssertEqual(received, authorizationState)
            
        })
        .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 300)
        XCTAssertEqual(didChangeCount, 0)

    }
    
    /// Matching state parameters supplied, but code verifier is invalid.
    func testInvalidCodeVerifier() {
        
        var didChangeCount = 0
        var cancellables: Set<AnyCancellable> = []
        Self.spotify.authorizationManagerDidChange.sink(receiveValue: {
            didChangeCount += 1
        })
        .store(in: &cancellables)
        
        let requestedScopes = Set(Scope.allCases.shuffled().prefix(5))
        let codeVerifier = String.randomURLSafe(length: 128)
        let codeChallenge = codeVerifier.makeCodeChallenge()
        let state = String.randomURLSafe(length: 128)
        
        let authorizationURL = Self.spotify.authorizationManager.makeAuthorizationURL(
            redirectURI: localHostURL,
            codeChallenge: codeChallenge,
            state: state,
            scopes: requestedScopes
        )!
        
        let queryDict = authorizationURL.queryItemsDict
        guard let scopesString = queryDict["scope"] else {
            XCTFail("Couldn't find 'scope' in query string: '\(authorizationURL)'")
            return
        }
        let scopesFromQuery = Scope.makeSet(scopesString)
        XCTAssertEqual(requestedScopes, scopesFromQuery)
        
        if let redirectURI = queryDict["redirect_uri"],
               let url = URL(string: redirectURI) {
            XCTAssertEqual(localHostURL, url)
        }
        else {
            XCTFail("couldn't find redirect_uri in query string")
        }
        
        XCTAssertEqual(queryDict["state"], state)
        XCTAssertEqual(queryDict["code_challenge"], codeChallenge)
        
        guard let redirectURL = openAuthorizationURLAndWaitForRedirect(
            authorizationURL
        ) else {
            XCTFail("redirect URL should not be nil")
            return
        }
        
        let expectation = XCTestExpectation(
            description: "testInvalidState: code verifier doesn't match " +
                         "code challenge"
        )
        
        Self.spotify.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: redirectURL,
            codeVerifier: "invalid_code_verifier_invalid_code_verifier_invalid",
            state: state
        )
        .sink(receiveCompletion: { completion in
            
            defer { expectation.fulfill() }

            guard case .failure(let error) = completion else {
                XCTFail(
                    "publisher should fail with SpotifyAuthenticationError"
                )
                return
            }
            guard let authenticationError = error as? SpotifyAuthenticationError else {
                XCTFail("error should be SpotifyAuthenticationError: \(error)")
                return
            }
            encodeDecode(authenticationError, areEqual: ==)
            print(authenticationError)
            
            XCTAssertEqual(authenticationError.error, "invalid_grant")
            XCTAssertEqual(
                authenticationError.description,
                "code_verifier was incorrect"
            )
            
        })
        .store(in: &Self.cancellables)
        
        self.wait(for: [expectation], timeout: 300)
        XCTAssertEqual(didChangeCount, 0)

    }
    
    override class func tearDown() {
        Self.spotify.authorizationManager.deauthorize()
    }

}
