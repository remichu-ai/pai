import LiveKit
import SwiftUI
import UIKit

struct LocalParticipantView: View {
    @EnvironmentObject private var room: Room
    
    var body: some View {
        ZStack {
            if let videoTrack = room.localParticipant.localVideoTracks.first?.track as? VideoTrack {
                LiveKitVideoView(track: videoTrack)
                    .cornerRadius(12)
            } else {
                // Placeholder when no video is available
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "video.slash")
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}
