import Foundation

struct SessionConfig: Codable {
    var modalities: [String] = ["text", "audio"]
    var instructions: String = ""
    var voice: String?
    var inputAudioFormat: String?
    var outputAudioFormat: String?
    var inputAudioTranscription: String?
    var turnDetection: TurnDetectionConfig = TurnDetectionConfig()
    var tools: [String] = []
    var toolChoice: String = "auto"
    var temperature: Double = 0.4
    var maxResponseOutputTokens: String = "inf"
    var video: VideoStreamSetting = VideoStreamSetting()
    var model: String?
    var streamingTranscription: Bool = true
    var userInterruptToken: String = " <user_interrupt>"
    var inputSampleRate: Int = 24000
    var outputSampleRate: Int = 24000
    var toolCallThinking: Bool = true
    var toolCallThinkingToken: Int = 200
    var toolInstructionPosition: String = "prefix"
    var toolSchemaPosition: String = "prefix"
}
