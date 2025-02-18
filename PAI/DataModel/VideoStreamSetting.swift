import Foundation

struct VideoStreamSetting: Encodable {
    var videoStream: Bool = true
    var videoMaxResolution: String? = "720p"
}
