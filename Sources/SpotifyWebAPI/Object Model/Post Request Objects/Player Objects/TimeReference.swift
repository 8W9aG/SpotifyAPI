import Foundation


/// Represents a period before or after a specified date. Dates are converted to
/// millisecond-precision timestamp strings.
///
/// Used in the body of `SpotifyAPI.recentlyPlayed(_:limit:)`.
public enum TimeReference: Codable, Hashable {
    
    /**
     A period before a specified date.
     
     The `String` value must be a unix timestamp in milliseconds, *rounded to*
     *the nearest integer*. For example: "1616355451022". This can be retrieved
     from the `before` property of a `SpotifyCursor`, if it is non-`nil`, in
     order to reference the page of results that chronologically precede the
     current page.
     
     See also `Self.before(_ date: Date)`.
     */
    case before(String)
    
    /**
     A period after a specified date.
     
     The `String` value must be a unix timestamp in milliseconds, *rounded to*
     *the nearest integer*. For example: "1616373716005". This can be retrieved
     from the `after` property of a `SpotifyCursor`, if it is non-`nil`, in
     order to reference the page of results that chronologically succeed the
     current page.
     
     See also `Self.after(_ date: Date)`.
     */
    case after(String)
    
    /**
     A period before a specified date. It will be converted to a
     millisecond-precision timestamp string rounded to the nearest integer.

     See also `Self.before(String)`.

     - Parameter date: A date.
     */
    public static func before(date: Date) -> TimeReference {
        return TimeReference.before(
            TimeReference.asMillisecondsString(date: date)
        )
    }
    
    /**
     A period before a specified date. It will be converted to a
     millisecond-precision timestamp string rounded to the nearest integer.
    
     See also `Self.after(String)`.

     - Parameter date: A date.
     */
    public static func after(date: Date) -> TimeReference {
        return TimeReference.after(
            TimeReference.asMillisecondsString(date: date)
        )
    }
    
    /// Converts the date to an *integer* representing the number of
    /// milliseconds since January 1, 1970.
    private static func asMillisecondsString(date: Date) -> String {
        return String(format: "%.0f", date.millisecondsSince1970)
    }

    
    /**
     Returns self as a query item.
     
     The name will be "before" or "after" and the value will be the date in
     milliseconds since the unix epoch rounded to the nearest whole number.
     */
    public func asQueryItem() -> [String: String] {
        let name: String
        let milliseconds: String
        switch self {
            case .before(let beforeTimestamp):
                name = "before"
                milliseconds = beforeTimestamp
            case .after(let afterTimestamp):
                name = "after"
                milliseconds = afterTimestamp
        }
        
        return [name: milliseconds]
    }
    
    /// :nodoc:
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let beforeTimestamp = try container.decodeIfPresent(
            String.self, forKey: .before
        ) {
            self = .before(beforeTimestamp)
        }
        else if let afterTimestamp = try container.decodeIfPresent(
            String.self, forKey: .after
        ) {
            self = .after(afterTimestamp)
        }
        else {
            
            let errorMessage = "expected to find key 'before' or 'after' " +
                "with String value"
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: errorMessage
                )
            )
            
        }
        
    }
    
    /// :nodoc:
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .before(let beforeTimestamp):
                try container.encode(
                    beforeTimestamp, forKey: .before
                )
            case .after(let afterTimestamp):
                try container.encode(
                    afterTimestamp, forKey: .after
                )
        }
        
    }
    
    private enum CodingKeys: String, CodingKey {
        case before, after
    }
}

extension TimeReference: ApproximatelyEquatable {
    
    /**
     Returns `true` if both instances are the same case of this enum and if the
     timestamps are approximately equal within an absolute tolerance of one
     second. Else, `false`.
     
     - Parameter other: Another instance of `Self`.
     */
    public func isApproximatelyEqual(to other: TimeReference) -> Bool {
        
        let timestamp: String
        let otherTimestamp: String

        switch (self, other) {
            case (.before(let beforeTimestamp), .before(let otherBeforeTimestamp)):
                timestamp = beforeTimestamp
                otherTimestamp = otherBeforeTimestamp
            case (.after(let afterTimestamp), .after(let otherAfterTimestamp)):
                timestamp = afterTimestamp
                otherTimestamp = otherAfterTimestamp
            default:
                return false
        }
        
        if let milliseconds = Int(timestamp),
                let otherMilliseconds = Int(otherTimestamp) {
            
            return milliseconds.isApproximatelyEqual(
                to: otherMilliseconds,
                // absolute tolerance of 1 second
                absoluteTolerance: 1_000,
                norm: { Double($0) }
            )
            
        }
        // shouldn't get to this point if the types are created properly;
        // they should always be parsable into integers
        return timestamp == otherTimestamp

    }

}
