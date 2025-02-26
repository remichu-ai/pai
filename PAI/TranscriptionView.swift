import LiveKit
import SwiftUI

struct TranscriptionView: View {
    @ObservedObject var delegate: TranscriptionDelegate
    @State private var userHasScrolledUp: Bool = false

    var body: some View {
        ScrollViewWithProxy()
            // Add some padding so the container doesn't stick to edges
            .padding(.horizontal)
            // Instead of a solid color, use a semi-translucent material
            .background(
                ColorConstants.controlBackgroundWithMaterial()
                    .cornerRadius(24)
                    .shadow(color: ColorConstants.buttonShadow, radius: 10, x: 0, y: 5)
            )
            // Let the transcript grow, but not beyond 250 points in height
            .frame(maxHeight: 200)
    }

    @ViewBuilder
    private func ScrollViewWithProxy() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                TranscriptionContent(
                    segments: delegate.receivedSegments,
                    segmentRole: delegate.segmentRole,
                    userHasScrolledUp: $userHasScrolledUp,
                    proxy: proxy
                )
            }
        }
    }
}

private struct TranscriptionContent: View {
    let segments: [TranscriptionSegment]
    let segmentRole: [String: String]
    @Binding var userHasScrolledUp: Bool
    let proxy: ScrollViewProxy

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MergedSegmentsList(segments: segments, segmentRole: segmentRole)
            BottomAnchor()
        }
        // Adjust overall padding inside the transcript
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(ScrollOffsetReader(userHasScrolledUp: $userHasScrolledUp))
        .onChange(of: segments) { _ in
            handleSegmentsChange(proxy: proxy)
        }
    }

    private func handleSegmentsChange(proxy: ScrollViewProxy) {
        withAnimation {
            if !userHasScrolledUp {
                proxy.scrollTo("BOTTOM", anchor: .bottom)
            }
        }
    }
}


private struct MergedSegmentsList: View {
    let segments: [TranscriptionSegment]
    let segmentRole: [String: String]

    var body: some View {
        ForEach(mergedMessages, id: \.id) { message in
            MessageView(text: message.text, isUser: message.isUser, isFinal: message.isFinal)
                .id(message.id)
        }
    }


    private struct MergedMessage: Identifiable {
        let id: String
        let text: String
        let isUser: Bool
        let isFinal: Bool
        let timestamp: Date
    }

    private var mergedMessages: [MergedMessage] {
        // Group segments by their ID and sort by received time
        let grouped = Dictionary(grouping: segments, by: { $0.id })
        var segmentList: [MergedMessage] = []
        
        for (id, segmentGroup) in grouped {
            // Sort each segment's updates by received time
            let sortedSegments = segmentGroup.sorted { $0.firstReceivedTime < $1.firstReceivedTime }
            // Use the latest (final) version of each segment
            if let finalSegment = sortedSegments.last {
                let role = segmentRole[id] ?? "unknown"
                segmentList.append(MergedMessage(
                    id: id,
                    text: finalSegment.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    isUser: role == "user",
                    isFinal: finalSegment.isFinal,
                    timestamp: finalSegment.firstReceivedTime
                ))
            }
        }
        
        // Sort by timestamp for correct order in conversation
        segmentList.sort { $0.timestamp < $1.timestamp }
        
        // Merge consecutive messages with the same role
        var mergedMessages: [MergedMessage] = []
        var currentText = ""
        var currentRole: Bool? = nil
        var currentTimestamp: Date?
        var currentIsFinal = false

        for message in segmentList {
            if currentRole == nil || currentRole == message.isUser {
                // Set currentRole if it is nil
                if currentRole == nil {
                    currentRole = message.isUser
                }
                if !currentText.isEmpty {
                    currentText += " " // Add a space between merged texts
                }
                currentText += message.text
                currentIsFinal = message.isFinal
                currentTimestamp = message.timestamp
            } else {
                // Save the previous merged message when the role changes
                if let timestamp = currentTimestamp, let role = currentRole, !currentText.isEmpty {
                    mergedMessages.append(MergedMessage(
                        id: UUID().uuidString, // Use a unique ID for merged messages
                        text: currentText,
                        isUser: role,
                        isFinal: currentIsFinal,
                        timestamp: timestamp
                    ))
                }
                // Start a new merged segment
                currentText = message.text
                currentRole = message.isUser
                currentIsFinal = message.isFinal
                currentTimestamp = message.timestamp
            }
        }

        // Append the last accumulated message
        if let timestamp = currentTimestamp, let role = currentRole, !currentText.isEmpty {
            mergedMessages.append(MergedMessage(
                id: UUID().uuidString,
                text: currentText,
                isUser: role,
                isFinal: currentIsFinal,
                timestamp: timestamp
            ))
        }
        
        print("Merged Messages: \(mergedMessages)")
        return mergedMessages
    }


}

private struct MessageView: View {
    let text: String
    let isUser: Bool
    let isFinal: Bool

    var body: some View {
        Text(text + (isFinal ? "" : " …"))
            .padding(8)
            // Keep distinct user vs. assistant backgrounds, or unify them if you prefer
            .background(isUser ? Color("TranscriptUserBG") : Color("TranscriptAIBG"))
            .cornerRadius(8)
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .foregroundColor(isUser ? Color("TranscriptUserText") : Color("TranscriptAIText"))
    }
}

private struct BottomAnchor: View {
    var body: some View {
        Color.clear
            .frame(height: 1)
            .id("BOTTOM")
    }
}

private struct ScrollOffsetReader: View {
    @Binding var userHasScrolledUp: Bool

    var body: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: ScrollOffsetPreferenceKey.self,
                value: geometry.frame(in: .global).minY
            )
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            userHasScrolledUp = value < -100
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
