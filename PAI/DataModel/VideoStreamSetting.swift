import Foundation

struct VideoStreamSetting: Codable {
    var videoStream: Bool = true
    var videoMaxResolution: String? = "720p"
    var retainVideo: String? = "message_based" // options: "disable", "message_based", "time_based"
    var retainPerMessage: Int = 1
    var secondPerRetain: Int = 3
    var maxMessageWithRetainedVideo: Int = 1

    enum CodingKeys: String, CodingKey {
        case videoStream = "video_stream"
        case videoMaxResolution = "video_max_resolution"
        case retainVideo = "retain_video"
        case retainPerMessage = "retain_per_message"
        case secondPerRetain = "second_per_retain"
        case maxMessageWithRetainedVideo = "max_message_with_retained_video"
    }
}
