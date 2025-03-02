import Foundation

struct VideoStreamSetting: Codable {
    var videoStream: Bool = true
    var videoMaxResolution: String? = "720p"
    
    enum CodingKeys: String, CodingKey {
        case videoStream = "video_stream"
        case videoMaxResolution = "video_max_resolution"
    }
}
