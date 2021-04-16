import Foundation

#if SWIFT_TOOLS_5_3

/// A namespace of images that can be used for
/// testing. They are stored in jpeg format.
public enum SpotifyExampleImages {
    
    /// A picture of Annabelle. 600 x 800; 121 KB of jpeg data.
    public static let annabelle: Data = {
        let url = Bundle.module.url(
            forResource: "Annabelle Compressed", withExtension: "jpeg"
        )!
        let data = try! Data(contentsOf: url)
        return data
    }()

}

#endif
