import LiveKit
import SwiftUI
import UIKit


struct LiveKitVideoView: UIViewRepresentable {
    var track: VideoTrack?
    
    func makeUIView(context: Context) -> VideoView {
        let videoView = VideoView()
        videoView.track = track
        return videoView
    }
    
    func updateUIView(_ uiView: VideoView, context: Context) {
        uiView.track = track
    }
}
