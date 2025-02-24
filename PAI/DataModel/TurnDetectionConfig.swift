import Foundation

struct TurnDetectionConfig: Codable {
    var type: String = "server_vad"
    var threshold: Double = 0.5
    var prefixPaddingMs: Int = 300
    var silenceDurationMs: Int = 400
    var createResponse: Bool = true
    var language: [String] = ["en", "vi"]
    var factorPrefixPaddingInTruncate: Bool = true
}
