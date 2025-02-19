import LiveKit
import SwiftUI

struct TranscriptionView: View {
    @ObservedObject var delegate: TranscriptionDelegate
    @State private var userHasScrolledUp: Bool = false

    var body: some View {
        ScrollViewWithProxy()
            .frame(height: 200)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
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
        .padding()
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
            
//            // Debug text
//            #if DEBUG
//            Text("Debug - Text: '\(message.text)' Final: \(message.isFinal ? "true" : "false")")
//                .font(.system(size: 10))
//                .foregroundColor(.gray)
//            #endif
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
        // Group segments by their ID to ensure latest updates are used
        let grouped = Dictionary(grouping: segments, by: { $0.id })
        var messages: [MergedMessage] = []
        
        for (id, segmentList) in grouped {
            // Sort each segment's history by received time
            let sortedSegments = segmentList.sorted { $0.firstReceivedTime < $1.firstReceivedTime }
            // Get the last known version of the segment (the final update, if available)
            if let finalSegment = sortedSegments.last {
                let role = segmentRole[id] ?? "unknown"
                messages.append(MergedMessage(
                    id: id,
                    text: finalSegment.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    isUser: role == "user",
                    isFinal: finalSegment.isFinal,
                    timestamp: finalSegment.firstReceivedTime
                ))
            }
        }
        
        // Sort messages by timestamp to maintain conversation order
        messages.sort { $0.timestamp < $1.timestamp }
        
        print("Merged Messages: \(messages)")
        return messages
    }
}

private struct MessageView: View {
    let text: String
    let isUser: Bool
    let isFinal: Bool

    var body: some View {
        Text(text + (isFinal ? "" : " …"))
            .padding(8)
            .background(isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
            .cornerRadius(8)
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .foregroundColor(isUser ? Color.blue : Color.primary)
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
