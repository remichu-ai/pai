import LiveKit
import SwiftUI

class TranscriptionDelegate: NSObject, ObservableObject, RoomDelegate {
    @Published var receivedSegments: [TranscriptionSegment] = []
    @Published var segmentRole: [String: String] = [:]
    
    override init() {
        super.init()
        print("TranscriptionDelegate has been initialized.")
    }
    
    func room(_ room: Room, participant: Participant, trackPublication: TrackPublication, didReceiveTranscriptionSegments segments: [TranscriptionSegment]) {
        Task { @MainActor in
            for segment in segments {
                // Append new segment update instead of overwriting
                self.receivedSegments.append(segment)
                self.segmentRole[segment.id] = participant.kind == .agent ? "assistant" : "user"
                
                // Debug prints
//                print("Segment ID: \(segment.id)")
//                print("Segment Text: \(segment.text)")
//                print("Is Final: \(segment.isFinal)")
//                print("Timestamp: \(segment.firstReceivedTime)")
//                print("Role: \(self.segmentRole[segment.id] ?? "unknown")")
//                print("-------------------")
            }
        }
    }
}
