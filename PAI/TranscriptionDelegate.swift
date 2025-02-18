import LiveKit
import SwiftUI

class TranscriptionDelegate: NSObject, RoomDelegate, ObservableObject {
    @Published var receivedSegments: [String: TranscriptionSegment] = [:]

    func room(_ room: Room, participant: Participant, trackPublication: TrackPublication, didReceiveTranscriptionSegments segments: [TranscriptionSegment]) {
        Task { @MainActor in
            for segment in segments {
                self.receivedSegments[segment.id] = segment
            }
        }
    }
}
