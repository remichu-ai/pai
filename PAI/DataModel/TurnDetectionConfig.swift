import Foundation

struct TurnDetectionConfig: Codable {
    var type: String = "server_vad"
    var threshold: Double = 0.5
    var prefixPaddingMs: Int = 300
    var silenceDurationMs: Int = 400
    var createResponse: Bool = true
    var language: [String] = ["en", "vi"]
    var factorPrefixPaddingInTruncate: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case type
        case threshold
        case prefixPaddingMs = "prefix_padding_ms"
        case silenceDurationMs = "silence_duration_ms"
        case createResponse = "create_response"
        case language
        case factorPrefixPaddingInTruncate = "factor_prefix_padding_in_truncate"
    }
}
